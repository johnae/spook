S = require 'syscall'
lfs = require "syscall.lfs"
ffi = require 'ffi'
Types = S.t
Constants = S.c
:define = require 'classy'
:is_callable = require 'utils'
:concat, insert: append = table
log = require 'log'
{:is_dir, :dirtree, :can_access} = require 'fs'

abi_os = require('syscall').abi.os
fd_evt_flag = abi_os == 'osx' and 'evtonly' or 'rdonly'

-- define something that identifies a watcher + a path uniquely
ffi.cdef [[
  typedef struct {
    uint8_t id;
    char path[1024];
  } watch_path;
]]

watch_path = ffi.typeof('watch_path')

MAX_EVENTS = 64
kqueue_fd = S.kqueue!

_next_id = 0
next_id = ->
  _next_id += 1
  _next_id
EventHandlers = {}

Timer = define 'Timer', ->
  properties
    stopped: => not @started

  instance
    initialize: (interval, callback) =>
      @interval = interval * 1000 -- kqueue takes ms
      @callback = callback
      @ident = next_id! -- NOTE: ident becomes the fd field when receiving event
      @filter = 'timer'
      @filter_num = Constants.EVFILT[@filter]
      @flags = 'add, oneshot'
      @data = @interval
      assert is_callable(@callback), "'callback' is required for a timer and must be a callable object (like a function)"
      @started = false

    __kevdata: (opts={}) =>
      :flags, :data = opts
      :ident, :filter = @
      flags or= @flags
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
      ev = Types.kevents {@__kevdata(flags: 'delete, oneshot')}
      kqueue_fd\kevent ev
      @started = false

  meta
    __call: =>
      EventHandlers["#{@filter_num}_#{@ident}"] = nil
      @started = false
      @callback!

ignored_signals = {}
signalblock = (signal) ->
  unless ignored_signals[signal]
    ignored_signals[signal] = true
    S.signal signal, 'ign'

signalunblock = (signal) ->
  if ignored_signals[signal]
    S.signal signal, 'dfl'
    ignored_signals[signal] = nil

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
    udata = watch_path :id, :path
    file = S.open path, fd_evt_flag
    kev = :filter, :flags, :udata, :fflags, fd: file\getfd!
    status = kqueue_fd\kevent Types.kevents({kev})
    assert status, "Failed to setup kqueue watch"
    {:modification, :access, :change, :size, :ino, :mode} = attr or lfs.attributes(path)
    watches[path] = :modification, :access, :change, :size, :ino, :mode, :file, :udata
    if is_dir(path)
      for entry, eattr in dirtree(path)
        if not is_dir(entry) or recursive
          watch entry, eattr, recursive
    watches
  unwatch = (path, recursive) ->
    if w = watches[path]
      file = w.file
      S.close file
      watches[path] = nil
      if is_dir(path) and recursive
        unwatch entry, recursive for entry, _ in dirtree path
  watch, unwatch, watches

convert_to_bsd_flags = (input) ->
  linux = [flag\trim! for flag in *(input\split(','))]
  bsd = {}
  for flag in *linux
    switch flag
--      when 'create'
      when 'delete'
        bsd[#bsd + 1] = flag
      when 'move'
        bsd[#bsd + 1] = 'rename'
      when 'modify'
        bsd[#bsd + 1] = 'write'
      when 'attrib'
        bsd[#bsd + 1] = 'attrib'
  concat bsd, ', '

watch_events = {}
coalesce_events = Timer.new 0.050, (t) ->
  for k, v in pairs watch_events
    handle = EventHandlers["#{v.filter}_#{v.id}"]
    watch_events[k] = nil
    handle and handle(v)
  t\again!

subdirs = (dir) ->
  dirs = {dir}
  for entry, attr in dirtree dir, true
    unless can_access(entry)
      log.debug "No access to #{entry}, skipping"
      continue
    if attr.mode == 'directory'
      dirs[#dirs + 1] = entry
  dirs

recurse_paths = (paths) ->
  all_paths = {}
  for p in *paths
    unless can_access(p)
      log.debug "No access to #{p}, skipping"
      continue
    if is_dir p
      for d in *subdirs(p)
        all_paths[#all_paths + 1] = d
      continue
    all_paths[#all_paths + 1] = p
  all_paths

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
        @paths = recurse_paths @_paths
      @fflags = convert_to_bsd_flags(watch_for)
      @watch_id = next_id!
      :fflags, :flags = @
      @watch, @unwatch, @watches = kq_watch @watch_id, :fflags, :flags
      @started = false

    start: =>
      coalesce_events\start! unless coalesce_events.started
      @stop!
      EventHandlers["#{@filter_num}_#{@watch_id}"] = @
      for path in *@_paths
        @.watch path, nil, @recursive
      @started = true

    stop: =>
      EventHandlers["#{@filter_num}_#{@watch_id}"] = nil
      for path in *@_paths
        @.unwatch path, @recursive
      @started = false

  meta
    __call: (e) =>
      events = {}
      has_rename = false
      for ev in *e
        {:path, :event} = ev
        if is_dir(path)
          for entry, _ in dirtree(path)
            unless @watches[entry]
              if is_dir(entry)
                if @recursive
                  append events, action: 'created', path: entry
                  @.watch entry, nil, @recursive
              else
                append events, action: 'created', path: entry
                append events, action: 'modified', path: entry
                @.watch entry, nil, @recursive
        else
          watch = @watches[path]
          continue unless watch

          if event.DELETE
            @.unwatch path
            append events, action: 'deleted', :path
            continue
          
          if event.RENAME
            has_rename = true
            append events, action: 'renamed', :path, attr: @watches[path]

          if event.WRITE
            append events, action: 'modified', :path

          if event.ATTRIB
            attr = lfs.attributes path
            old = @watches[path]
            if not old or old.size != attr.size or old.modification != attr.modification or old.change != attr.change
              append events, action: 'attrib', :path
            for key in *{'modification', 'access', 'change', 'size', 'ino', 'mode'}
              @watches[path][key] = attr[key] if attr[key]

      if has_rename
        new_events = {}
        skip = {}
        moves = {}
        ino = (ev) ->
          if ev.action == 'renamed'
            ev.attr.ino
          else
            lfs.attributes(ev.path).ino
        renames = [{idx, ino(ev)} for idx, ev in ipairs(events) when ev.action == 'renamed']
        creates = [{idx, ino(ev)} for idx, ev in ipairs(events) when ev.action == 'created']
        modifies = [{idx, ino(ev)} for idx, ev in ipairs(events) when ev.action == 'modified']
        for rename in *renames
          for create in *creates
            if rename[2] == create[2]
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

      @callback events unless #events == 0

Read = define 'Read', ->
  properties
    stopped: => not @started
    fdnum: => @fd\getfd!

  instance
    initialize: (fd, callback) =>
      assert type(fd) != 'number', "Only takes wrapped fd:s, please use type helper 'fd' from syscall/methods.lua"
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
  block_for = block_for / 1000 -- kqueue takes seconds it seems
  for _, v in wait_for_events block_for
    if v.filter == Constants.EVFILT['vnode']
      wp = ffi.cast('watch_path*', v.udata)
      id, path = tonumber(wp.id), ffi.string(wp.path)
      ev = watch_events["#{v.filter}_#{id}"] or {:id, filter: v.filter}
      watch_events["#{v.filter}_#{id}"] = ev
      append ev, {:path, event: v}
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

:Timer, :Signal, :Read, :Watcher, :EventHandlers, :kqueue_fd, :run, :run_once, :clear_all
