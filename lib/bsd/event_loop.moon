S = require 'syscall'
lfs = require "syscall.lfs"
ffi = require 'ffi'
Types = S.t
Constants = S.c
:define = require 'classy'
:is_callable = require 'utils'
:concat, insert: append = table
{:unique_subtrees, :is_dir, :dirtree, :can_access} = require 'fs'

abi_os = require('syscall').abi.os
fd_evt_flag = abi_os == 'osx' and 'evtonly' or 'rdonly'
-- fix on freebsd 12 but then ljsyscall itself needs fixes
ino_t = abi_os == 'osx' and 'ino64_t' or 'ino_t'

-- define something that a "watch" points to
ffi.cdef "
  typedef struct {
    uint64_t id;
    #{ino_t} ino;
  } watch_data;
"

watch_data = ffi.typeof('watch_data')

MAX_EVENTS = 512
kqueue_fd = S.kqueue!

_next_id = 0
next_id = ->
  _next_id += 1
  _next_id
EventHandlers = {}

Timer = define 'Timer', ->
  properties
    stopped: => not @started
    addflags: => "add, #{@type}"
    delflags: => "delete, #{@type}"
    recurring:
      get: => @_recurring
      set: (bool) =>
        @stop!
        @_recurring = bool
        @type = if @_recurring
          "enable"
        else
          "oneshot"

  instance
    initialize: (interval, callback) =>
      -- kqueue uses a timespec, when initializing that with single value it takes seconds
      -- to be compatible with the linux version (which assumes ms) we "fix" that here
      @interval = interval * 1000
      @callback = callback
      @ident = next_id! -- NOTE: ident becomes the fd field when receiving event
      @filter = 'timer'
      @filter_num = Constants.EVFILT[@filter]
      @type = "oneshot"
      @data = @interval
      assert is_callable(@callback), "'callback' is required for a timer and must be a callable object (like a function)"
      @started = false
      @_recurring = false

    __kevdata: (opts={}) =>
      :flags, :data = opts
      :ident, :filter = @
      flags or= @addflags
      data or= @data
      :ident, :filter, :flags, :data

    start: =>
      @stop!
      @again!
      @started = true

    again: =>
      EventHandlers["#{@filter_num}_#{@ident}"] = @
      kqueue_fd\kevent Types.kevents({@__kevdata!})

    stop: =>
      EventHandlers["#{@filter_num}_#{@ident}"] = nil
      ev = Types.kevents {@__kevdata(flags: @delflags)}
      kqueue_fd\kevent ev
      @started = false

  meta
    __call: =>
      unless @_recurring
        EventHandlers["#{@filter_num}_#{@ident}"] = nil
        @started = false
      @callback!

ignored_signals = {}
signalblock = (signal) ->
  sig = signal\lower!
  return if sig == "chld"
  unless ignored_signals[sig]
    ignored_signals[sig] = true
    S.signal sig, 'ign'

signalunblock = (signal) ->
  sig = signal\lower!
  if ignored_signals[sig]
    S.signal sig, 'dfl'
    ignored_signals[sig] = nil

signalreset = ->
  signalunblock sig for sig in pairs ignored_signals

Signal = define 'Signal', ->
  properties
    stopped: => not @started

  instance
    initialize: (signal, callback) =>
      @callback = callback
      @signal = signal
      @filter = 'signal'
      @filter_num = Constants.EVFILT[@filter]
      @ident = Constants.SIG[@signal]
      @flags = 'add'
      assert is_callable(@callback), "'callback' is required for a timer and must be a callable object (like a function)"
      @started = false

    __kevdata: (opts={}) =>
      :flags = opts
      :signal, :filter = @
      flags or= @flags
      :filter, :flags, :signal

    start: =>
      EventHandlers["#{@filter_num}_#{@ident}"] = @
      signalblock @signal
      kqueue_fd\kevent Types.kevents({@__kevdata!})
      @started = true

    stop: =>
      EventHandlers["#{@filter_num}_#{@ident}"] = nil
      signalunblock @signal
      kqueue_fd\kevent Types.kevents {@__kevdata(flags: 'delete')}
      @started = false

  meta
    __call: =>
      @callback!

-- watcher helpers

kq_watch = (id, opts={}) ->
  watches = {}
  filter = Constants.EVFILT['vnode']
  id = assert id, "Error, no id given"
  flags = opts.flags or 'add, enable, clear'
  fflags = opts.fflags or 'delete, write, rename, attrib'
  watch = (path, attr, recursive) ->
    file, err = S.open path, fd_evt_flag
    if err
      error "#{path}: #{tostring(err)}"
    attr or= lfs.attributes path
    udata = watch_data :id, ino: attr.ino
    kev = :filter, :flags, :udata, :fflags, fd: file\getfd!
    status = kqueue_fd\kevent Types.kevents({kev})
    assert status, "Failed to setup kqueue watch"
    {:modification, :access, :change, :size, :ino, :mode} = attr or lfs.attributes(path)
    watches[ino] = :path, :modification, :access, :change, :size, :ino, :mode, :file, :udata
    if is_dir(path)
      for entry, eattr in dirtree(path)
        if not is_dir(entry) or recursive
          watch entry, eattr, recursive
    watches
  unwatch = (ino, recursive) ->
    if w = watches[ino]
      path = w.path
      file = w.file
      S.close file
      watches[ino] = nil
      if is_dir(path) and recursive
        unwatch attr.ino, recursive for _, attr in dirtree path
  watch, unwatch, watches

convert_to_bsd_flags = (input) ->
  linux = [flag\trim! for flag in *(input\split(','))]
  bsd = {}
  for flag in *linux
    switch flag
--      when 'create'
      when 'delete'
        append bsd, flag
      when 'move'
        append bsd, 'rename'
      when 'modify'
        append bsd, 'write'
      when 'attrib'
        append bsd, 'attrib'
  concat bsd, ', '

watch_events = {}
coalesce_events = Timer.new 0.050, (t) ->
  for k, v in pairs watch_events
    handle = EventHandlers["#{v.filter}_#{v.id}"]
    watch_events[k] = nil
    handle and handle(v)
  t\again!


Watcher = define 'Watcher', ->
  properties
    stopped: => not @started

  instance
    initialize: (paths, watch_for, opts={}) =>
      @recursive = opts.recursive or false
      @callback = opts.callback
      assert is_callable(@callback), "'callback' is a required option for a Watcher and must be a callable object (like a function)"
      paths = type(paths) == 'table' and paths or {paths}
      @filter_num = Constants.EVFILT['vnode']
      @flags = 'add, enable, clear'
      @_paths = [path for path in *paths when can_access(path)]
      if #@_paths == 0
        error "None of the given paths (#{concat ["'#{path}'" for path in *paths], ', '}) were accessible"
      @paths = @_paths
      if @recursive
        @paths = unique_subtrees @_paths
      @fflags = convert_to_bsd_flags(watch_for)
      @watch_id = next_id!
      :fflags, :flags = @
      @watch, @unwatch, @watches = kq_watch @watch_id, :fflags, :flags
      @started = false
      @inodes = {}

    start: =>
      coalesce_events\start! unless coalesce_events.started
      @stop!
      EventHandlers["#{@filter_num}_#{@watch_id}"] = @
      for path in *@_paths
        w = @.watch path, nil, @recursive
        for inode in pairs w
          @inodes[inode] = true
      @started = true

    stop: =>
      EventHandlers["#{@filter_num}_#{@watch_id}"] = nil
      for inode in pairs @inodes
        @.unwatch inode, @recursive
      @started = false

  meta
    __call: (e) =>
      events = {}
      has_rename = false
      for ev in *e
        {:event, :ino} = ev
        unless @watches[ino]
          -- we may have removed the watch
          continue
        path = @watches[ino].path

        if is_dir(path)
          for entry, attr in dirtree(path)
            watches = [w for _, w in pairs @watches when w.path == entry]
            if #watches == 0 or watches[1].ino != attr.ino
              if is_dir(entry)
                if @recursive
                  append events, {action: 'created', path: entry, ino: attr.ino}
                  @.watch entry, attr, @recursive
              else
                append events, {action: 'created', path: entry, ino: attr.ino}
                append events, {action: 'modified', path: entry, ino: attr.ino}
                @.watch entry, attr, @recursive
        else

          if event.DELETE
            @.unwatch ino
            append events, {action: 'deleted', :path, :ino}

          if event.RENAME
            has_rename = true
            append events, {action: 'renamed', :path, :ino, attr: @watches[ino]}

          if event.WRITE
            append events, {action: 'modified', :path, :ino}

          if event.ATTRIB
            attr = lfs.attributes path
            if attr
              old = @watches[ino]
              if not old or old.size != attr.size or old.modification != attr.modification or old.change != attr.change
                append events, {action: 'attrib', :path, :ino}
              for key in *{'modification', 'access', 'change', 'size', 'ino', 'mode'}
                @watches[ino][key] = attr[key] if attr[key]

      if has_rename
        new_events = {}
        skip = {}
        moves = {}

        renames = [{idx, ev.ino} for idx, ev in ipairs(events) when ev.action == 'renamed']
        creates = [{idx, ev.ino} for idx, ev in ipairs(events) when ev.action == 'created']
        modifies = [{idx, ev.ino} for idx, ev in ipairs(events) when ev.action == 'modified']
        for rename in *renames
          for create in *creates
            continue if rename[2] == nil or create[2] == nil
            if rename[2] == create[2]
              @watches[rename[2]].path = events[create[1]].path
              append moves, {
                from: events[rename[1]].path
                to: events[create[1]].path
                path: events[create[1]].path
                action: 'moved'
              }
              skip[rename[1]] = true
              skip[create[1]] = true
              for m in *modifies
                if m[2] == create[2]
                  skip[m[1]] = true
        for idx, event in ipairs events
          append new_events, event unless skip[idx]
        events = new_events
        for move in *moves
          append events, move

      for ev in *events
        ev.ino = nil
        while ev.path\sub(1,2) == './'
          ev.path = ev.path\gsub '^%./', ''

      @callback events unless #events == 0

Read = define 'Read', ->
  properties
    stopped: => not @started
    fdnum: => @fd\getfd!

  instance
    initialize: (fd, callback) =>
      assert type(fd) != 'number', "Read only takes wrapped fd:s, please use type helper 'fd' from syscall/methods.lua, see: https://github.com/justincormack/ljsyscall"
      @fd = fd
      @callback = callback
      @filter = 'read'
      @filter_num = Constants.EVFILT[@filter]
      @flags = 'add'
      assert is_callable(@callback), "'callback' is required for a signal and must be a callable object (like a function)"
      @started = false

    __kevdata: (opts={}) =>
      :flags = opts
      :filter = @
      flags or= @flags
      :filter, :flags, fd: @fdnum

    start: =>
      EventHandlers["#{@filter_num}_#{@fdnum}"] = @
      kqueue_fd\kevent Types.kevents({@__kevdata!}), nil
      @started = true

    stop: =>
      EventHandlers["#{@filter_num}_#{@fdnum}"] = nil
      kqueue_fd\kevent Types.kevents {@__kevdata(flags: 'delete')}
      @started = false

  meta
    __call: =>
      @callback @fd

wait_for_events = (block_for) ->
  kqueue_events = Types.kevents MAX_EVENTS
  nilf = ->
  f, a, r = kqueue_fd\kevent nil, kqueue_events, block_for
  return f, a, r if f
  nilf

run_once = (opts={}) ->
  process = opts.process or -> nil
  block_for = opts.block_for or 500 -- default 500 ms blocking wait
  -- kqueue uses a timespec, when initializing that with single value it takes seconds
  -- to be compatible with the linux version (which assumes ms) we "fix" that here
  block_for = block_for / 1000
  for _, v in wait_for_events block_for
    if v.filter == Constants.EVFILT['vnode']
      wp = ffi.cast('watch_data*', v.udata)
      id, ino = tonumber(wp.id), tonumber(wp.ino)
      ev = watch_events["#{v.filter}_#{id}"] or {:id, filter: v.filter}
      watch_events["#{v.filter}_#{id}"] = ev
      append ev, {:ino, event: v}
    else
      handle = EventHandlers["#{v.filter}_#{v.fd}"]
      handle and handle!

  process!

run = (opts={}) ->
  while true
    run_once opts

clear_all = ->
  for _, v in pairs EventHandlers
    v\stop! if v

:Timer, :Signal, :Read, :Watcher, :EventHandlers, :kqueue_fd, :run, :run_once, :clear_all, :signalblock, :signalunblock, :signalreset
