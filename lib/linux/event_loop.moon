S = require "syscall"
Types = S.t
define = require'classy'.define
{:is_dir, :dirtree} = require 'fs'

epoll_fd = S.epoll_create 'cloexec'
epoll_events = Types.epoll_events 1

subdirs = (dir) ->
  dirs = {dir}
  for entry, attr in dirtree dir, true
    if attr.mode == 'directory'
      dirs[#dirs + 1] = entry
  dirs

recurse_paths = (paths) ->
  all_paths = {}
  for p in *paths
    if is_dir p
      for d in *subdirs(p)
        all_paths[#all_paths + 1] = d
      continue
    all_paths[#all_paths + 1] = p
  all_paths

EventHandlers = {}
Watcher = define 'Watcher', ->
  properties
    fdnum: => @fd\getfd!
    events: =>
      n, _ = @fd\inotify_read!
      events = {}
      if n and #n > 0
        moves = [ev for ev in *n when ev.cookie != 0]
        other = [ev for ev in *n when ev.cookie == 0]
        for ev in *other
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
            path = dir == '.' and ev_name or "#{dir}/#{ev_name}"
          events[#events + 1] = action: evname, :path

        if #moves > 0
          cookies = {k.cookie, true for k in *moves}
          for cookie, _ in pairs cookies
            data = action: 'moved', id: cookie
            related = [ev for ev in *moves when ev.cookie == cookie]
            for ev in *related
              wd = ev.wd
              dir = @watchers[wd]
              path = dir == '.' and ev.name or "#{dir}/#{ev.name}"
              if ev.moved_from
                data.from = path
              else
                data.to = path
                data.path = path
            events[#events + 1] = data
      events

  instance
    initialize: (paths, watch_for, opts={}) =>
      @fd = S.inotify_init 'cloexec, nonblock'
      @recursive = opts.recursive or false
      @callback = opts.callback
      assert type(@callback) == 'function', "'callback' is a required option and must be a callable object (like a function)"
      @paths = type(paths) == 'table' and paths or {paths}
      if @recursive
        @paths = recurse_paths @paths
      @watch_for = watch_for
      @watchers = {}
      EventHandlers[@fdnum] = @

    start: =>
      @stop!
      for p in *@paths
        wd = @fd\inotify_add_watch p, @watch_for
        @watchers[wd] = p
      epoll_fd\epoll_ctl 'add', @fdnum, 'in'

    stop: =>
      epoll_fd\epoll_ctl 'del', @fdnum, 'in'
      for k, _ in pairs @watchers
        @fd\inotify_rm_watch k
      @watchers = {}

  meta
    __call: =>
      @callback @events

Timer = define 'Timer', ->
  properties
    fdnum: => @fd\getfd!

  instance
    initialize: (interval, callback) =>
      @fd = S.timerfd_create 'monotonic', 'cloexec, nonblock'
      @interval = interval
      @callback = callback
      assert type(@callback) == 'function', "'callback' is required for a timer and must be a callable object (like a function)"
      EventHandlers[@fdnum] = @

    start: =>
      @again!
      epoll_fd\epoll_ctl 'add', @fdnum, 'in'

    again: =>
      @fd\timerfd_settime nil, {0,@interval}

    stop: =>
      epoll_fd\epoll_ctl 'del', @fdnum, 'in'

  meta
    __call: =>
      -- if we don't read it, epoll will continue returning it (unless in edge triggered mode, but we don't use that here)
      S.util.timerfd_read @fdnum
      @callback!

Signal = define 'Signal', ->
  properties
    fdnum: => @fd\getfd!

  instance
    initialize: (signals, callback) =>
      @signals = signals
      @fd = S.signalfd @signals
      @callback = callback
      assert type(@callback) == 'function', "'callback' is required for a signal and must be a callable object (like a function)"
      EventHandlers[@fdnum] = @

    start: =>
      S.sigprocmask("block", @signals)
      epoll_fd\epoll_ctl 'add', @fdnum, 'in'

    stop: =>
      S.sigprocmask("unblock", @signals)
      epoll_fd\epoll_ctl 'del', @fdnum, 'in'

  meta
    __call: =>
      S.util.signalfd_read @fdnum
      @callback!

run_once = (opts={}) ->
  process = opts.process or -> nil
  block_for = opts.block_for or 10 -- default 10 ms blocking wait
  process or= -> nil
  for k, v in epoll_fd\epoll_wait(epoll_events, block_for)
    handle = EventHandlers[v.fd]
    handle and handle!
  process!

run = (opts={}) ->
  while true
    run_once opts

:Watcher, :Timer, :Signal, :epoll_fd, :run, :run_once
