require 'globals'
:empty, :concat, insert: append = table
define = require'classy'.define
log = require 'log'
{:Watcher, :Timer, :Signal, :Read} = require "event_loop"
Queue = require 'queue'
Event = require 'event'
:to_coro = require 'utils'

define 'Spook', ->
  properties
    log_level:
      get: => @_log_level
      set: (v) =>
        @_log_level = v
        log.level log[@_log_level]

    all_event_emitters: =>
      emitters = [w for w in *@watchers]
      for timer in *@timers
        append emitters, timer
      for reader in *@readers
        append emitters, reader
      unless empty @signals
        for _, signal in pairs @signals
          append emitters, signal
      emitters

    first_match_only:
      get: => @_first_match_only
      set: (bool) => @_first_match_only = bool

  instance
    initialize: =>
      @caller_env = {}
      @timers = {}
      @readers = {}
      @signals = {}
      @at_exit = {}
      @watchers = {}
      @num_dirs = 0
      @file_watches = 0
      @first_match_only = true
      @queue = Queue.new!
      @watches = {changed: {}, deleted: {}, moved: {}, created: {}, modified: {}, attrib: {}}
      @handlers = {}
      for wname, store in pairs @watches
        @handlers["on_#{wname}"] = (pattern, func) ->
          append store, {pattern, to_coro(func)}
      setmetatable @handlers, __index: _G
      @_log_level =  log.INFO
      for f in *{'watch', 'watch_file', 'timer', 'every', 'after', 'on_signal', 'on_read'}
        @caller_env[f] = (...) -> @[f] @, ...
      @caller_env.queue = @queue
      @caller_env.log_level = (v) ->
        if @_log_level == log.INFO
          @log_level = v
      @caller_env.first_match_only = (b) -> @first_match_only = b
      setmetatable @caller_env, __index: _G
      -- always have something defined here that does the proper thing
      @on_signal 'int', (s) -> os.exit(1)

    -- defines recursive watchers (eg. all directories underneath given directories)
    watch: (...) =>
      args = {...}
      dirs = [d for i, d in ipairs args when i<#args]
      func = args[#args]
      unless type(func) == 'function'
        error 'last argument to watch must be a setup function'
      new_watcher = Watcher.new dirs, 'create, delete, modify, move, attrib', recursive: true, callback: (w, events) ->
        for e in *events
          @queue\pushright Event.new('fs', e)
      append @watchers, new_watcher
      @num_dirs += #new_watcher.paths
      setfenv func, @handlers
      func!
      new_watcher

    watch_file: (file, func) =>
      dir = '.'
      path = file\split '/'
      if #path > 1
        file = path[#path]
        dir = concat [comp for comp in *path when comp!=path[#path]], '/'
      old_handlers = @handlers
      @handlers = {}
      for wname, store in pairs @watches
        @handlers["on_#{wname}"] = (fun) -> append store, {file, to_coro(fun)}
      @watchnr dir, func
      @file_watches += 1
      @handlers = old_handlers

    -- defines non-recursive watchers (eg. only given directories are watched)
    -- only used internally for now.
    watchnr: (...) =>
      args = {...}
      dirs = [d for i, d in ipairs args when i<#args]
      func = args[#args]
      unless type(func) == 'function'
        error 'last argument to watch must be a setup function'
      new_watcher = Watcher.new dirs, 'create, delete, modify, move, attrib', callback: (w, events) ->
        for e in *events
          @queue\pushright Event.new('fs', e)
      append @watchers, new_watcher
      setfenv func, @handlers
      func!
      new_watcher

    timer: (interval, callback) =>
      new_timer = Timer.new interval, to_coro(callback)
      append @timers, new_timer
      new_timer

    after: (interval, callback) =>
      new_timer = Timer.new interval, to_coro(callback)
      append @timers, new_timer
      new_timer

    every: (interval, callback) =>
      new_timer = Timer.new interval, to_coro(callback)
      new_timer.recurring = true
      append @timers, new_timer
      new_timer

    on_read: (fd, callback) =>
      new_reader = Read.new fd, to_coro(callback)
      append @readers, new_reader
      new_reader

    -- this is currently a bit dangerous since what one would do on say SIGINT
    -- is probably some cleanup action after which os.exit is called. But what
    -- if someone adds SIGINT and a callback and in some other place the same
    -- thing is done expecting to also run? Need a better way here.
    on_signal:  (signal, callback) =>
      signal = signal\lower!
      assert signal\match("[%s,]") == nil, "Signals can't contain whitespace or commas, for several - please specify them individually"
      if old = @signals[signal]
        old\stop!
      new_signal = Signal.new signal, to_coro(callback)
      @signals[signal] = new_signal
      new_signal

    start: =>
      for e in *@all_event_emitters
        e\start!

    stop: =>
      for e in *@all_event_emitters
        e\stop!

    match: (event) =>
      return unless type(event) == 'table' and event.type == 'fs'
      return if event.action == 'unknown'
      matching = {}
      matchers = [m for m in *@watches[event.action]]
      unless event.action == 'deleted'
        for m in *@watches.changed
          append matchers, m
      for matcher in *matchers
        p, f = matcher[1], matcher[2]
        matches = {event.path\match p}
        if #matches > 0
          append matching, -> f(event, unpack(matches))
      matching

  meta
    __call: (func) =>
      setfenv func, @caller_env
      func!
