S = require 'syscall'
Types = S.t
Util = S.util
:define = require 'classy'
:unique_subtrees, :can_access = require 'fs'
:concat, insert: append = table
:is_callable = require 'utils'

MAX_EVENTS = 1024

epoll_fd = S.epoll_create 'cloexec'
epoll_events = Types.epoll_events MAX_EVENTS

EventHandlers = {}
num_watches = 0
Watcher = define 'Watcher', ->
  properties
    stopped: => not @started
    fdnum: => @fd\getfd!
    events: =>
      n = @fd\inotify_read!
      cookies_handled = {}
      events = {}
      handle_move = (ev) ->
        return if cookies_handled[ev.cookie]
        cookies_handled[ev.cookie] = true
        data = action: 'moved'
        related = [rev for rev in *n when rev.cookie == ev.cookie]
        for rev in *related
          wd = rev.wd
          dir = @watchers[wd]
          path = dir == '.' and rev.name or "#{dir}/#{rev.name}"
          if rev.moved_from
            data.from = path
          else
            data.to = path
            data.path = path
        append events, data

      handle_other = (ev) ->
        evname = switch true
          when ev.create
            'created'
          when ev.delete
            'deleted'
          when ev.modify
            'modified'
          when ev.attrib
            'attrib'
          when ev.open
            'opened'
          else
            'unknown'
        wd = ev.wd
        dir = @watchers[wd]
        path = nil
        unless evname == 'unknown'
          ev_name = rawget ev, 'name'
          path = "#{dir}/#{ev_name}"
          while path\sub(1,2) == './'
            path = path\gsub '^%./', ''

        append events, {action: evname, :path}

      if n and #n > 0
        for ev in *n
          if ev.cookie != 0
            handle_move ev
          else
            handle_other ev
      events

  instance
    initialize: (paths, watch_for, opts={}) =>
      @fd, err = S.inotify_init 'cloexec, nonblock'
      if err != nil
        error tostring(err)
      @recursive = opts.recursive or false
      @callback = opts.callback
      assert is_callable(@callback), "'callback' is a required option for a Watcher and must be a callable object (like a function)"
      paths = type(paths) == 'table' and paths or {paths}
      @paths = [path for path in *paths when can_access(path)]
      if #@paths == 0
        error "None of the given paths (#{concat ["'#{path}'" for path in *paths], ', '}) were accessible"
      if @recursive
        if opts.follow_links == false
          @paths = unique_subtrees @paths, false
        else
          @paths = unique_subtrees @paths, true
      @watch_for = watch_for
      @watchers = {}
      @started = false

    start: =>
      @stop!
      EventHandlers[@fdnum] = @
      for p in *@paths
        wd, err = @fd\inotify_add_watch p, @watch_for
        unless wd
          error "#{tostring(err)}, not allowed to add more inotify watches (this spook instance is currently at #{num_watches}) - see /proc/sys/fs/inotify/max_user_watches"
        num_watches += 1
        continue unless wd
        @watchers[wd] = p
      epoll_fd\epoll_ctl 'add', @fdnum, 'in'
      @started = true

    stop: =>
      EventHandlers[@fdnum] = nil
      epoll_fd\epoll_ctl 'del', @fdnum, 'in'
      for k, _ in pairs @watchers
        @fd\inotify_rm_watch k
        num_watches -= 1
      @watchers = {}
      @started = false

  meta
    __call: =>
      @callback @events

Timer = define 'Timer', ->
  properties
    stopped: => not @started
    fdnum: => @fd\getfd!
    recurring:
      get: => @_recurring
      set: (bool) =>
        @stop!
        @_recurring = true
        @timespec = if @_recurring
          {@interval, @interval}
        else
          {0, @interval}

  instance
    initialize: (interval, callback) =>
      @fd, err = S.timerfd_create 'monotonic', 'cloexec, nonblock'
      if err != nil
        error tostring(err)
      @interval = interval
      @callback = callback
      assert is_callable(@callback), "'callback' is required for a timer and must be a callable object (like a function)"
      @started = false
      @_recurring = false
      @timespec = {0, @interval}

    start: =>
      @stop!
      @again!
      epoll_fd\epoll_ctl 'add', @fdnum, 'in'
      @started = true

    again: =>
      EventHandlers[@fdnum] = @
      @fd\timerfd_settime nil, @timespec

    stop: =>
      EventHandlers[@fdnum] = nil
      epoll_fd\epoll_ctl 'del', @fdnum, 'in'
      @started = false

  meta
    __call: =>
      -- if we don't read it, epoll will continue returning it (unless in edge triggered mode, but we don't use that here)
      Util.timerfd_read @fdnum
      unless @_recurring
        EventHandlers[@fdnum] = nil
        @started = false
      @callback!

signalset = S.sigprocmask!
signalblock = (signal) ->
  sig = signal\lower!
  signalset\add sig
  S.sigprocmask("block", signalset)

signalunblock = (signal) ->
  sig = signal\lower!
  signalset\del sig
  S.sigprocmask("block", signalset)

signalreset = -> S.sigprocmask("unblock", signalset)

Signal = define 'Signal', ->
  properties
    stopped: => not @started
    fdnum: => @fd\getfd!

  instance
    initialize: (signals, callback) =>
      @signals = signals
      @fd, err = S.signalfd @signals, 'cloexec, nonblock'
      if err != nil
        error tostring(err)
      @callback = callback
      assert is_callable(@callback), "'callback' is required for a signal and must be a callable object (like a function)"
      @started = false

    start: =>
      EventHandlers[@fdnum] = @
      signalblock @signals
      epoll_fd\epoll_ctl 'add', @fdnum, 'in'
      @started = true

    stop: =>
      EventHandlers[@fdnum] = nil
      signalunblock @signals
      epoll_fd\epoll_ctl 'del', @fdnum, 'in'
      @started = false

  meta
    __call: =>
      Util.signalfd_read @fdnum
      @callback!

Read = define 'Read', ->
  properties
    stopped: => not @started
    fdnum: => @fd\getfd!

  instance
    initialize: (fd, callback) =>
      assert type(fd) != 'number', "Read only takes wrapped fd:s, please use type helper 'fd' from syscall/methods.lua, see: https://github.com/justincormack/ljsyscall"
      @fd = fd
      @callback = callback
      @options = 'in'
      assert is_callable(@callback), "'callback' is required for a Reader and must be a callable object (like a function)"
      @started = false

    start: =>
      EventHandlers[@fdnum] = @
      epoll_fd\epoll_ctl 'add', @fdnum, @options
      @started = true

    stop: =>
      EventHandlers[@fdnum] = nil
      epoll_fd\epoll_ctl 'del', @fdnum, @options
      @started = false

  meta
    __call: =>
      @callback @fd

-- get around the issue of epoll returning nil
-- when the process receives a SIGSTOP
wait_for_events = (block_for) ->
  nilf = ->
  f, a, r = epoll_fd\epoll_wait epoll_events, block_for
  return f, a, r if f
  nilf

run_once = (opts={}) ->
  process = opts.process or -> nil
  block_for = opts.block_for or 500 -- default 500 ms blocking wait
  process or= -> nil
  for _, v in wait_for_events block_for
    handle = EventHandlers[v.fd]
    handle and handle!
  process!

run = (opts={}) ->
  while true
    run_once opts

clear_all = ->
  for _, v in pairs EventHandlers
    v\stop! if v

:Watcher, :Timer, :Signal, :Read, :epoll_fd, :run, :run_once, :clear_all, :signalblock, :signalunblock, :signalreset
