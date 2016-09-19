define = require'classy'.define
log = require 'log'
{:Watcher, :Timer, :Signal} = require "event_loop"
Queue = require 'queue'
Event = require 'event'

define 'Spook', ->
  properties
    log_level:
      get: => @_log_level
      set: (v) =>
        @_log_level = v
        log.log_level = log[@_log_level]

    all_event_emitters: =>
      emitters = [w for w in *@watchers]
      for t in *@timers
        emitters[#emitters + 1] = t
      for s in *@signals
        emitters[#emitters + 1] = s
      emitters

  instance
    initialize: =>
      @caller_env = {}
      @timers = {}
      @signals = {}
      @at_exit = {}
      @watchers = {}
      @num_dirs = 0
      @numnr_dirs = 0
      @queue = Queue.new!
      @watches = {changed: {}, deleted: {}, moved: {}, created: {}, modified: {}, attrib: {}}
      @handlers = {}
      for wname, store in pairs @watches
        @handlers["on_#{wname}"] = (pattern, func) -> store[#store + 1] = {pattern, func}
      setmetatable @handlers, __index: _G
      @_log_level =  log.INFO
      for f in *{'watch', 'watchnr', 'timer', 'signal'}
        @caller_env[f] = (...) -> @[f] @, ...
      @caller_env.queue = @queue
      @caller_env.log_level = (v) -> @log_level = v
      setmetatable @caller_env, __index: _G

    -- defines recursive watchers (eg. all directories underneath given directories)
    watch: (...) =>
      args = {...}
      dirs = [d for i, d in ipairs args when i<#args]
      func = args[#args]
      unless type(func) == 'function'
        error 'last argument to watch must be a setup function'
      @watchers[#@watchers + 1] = Watcher.new dirs, 'create, delete, modify, move, attrib', recursive: true, callback: (w, events) ->
        for e in *events
          @queue\pushright Event.new('fs', e)
      @num_dirs += #@watchers[#@watchers].paths
      setfenv func, @handlers
      func!
      @watchers[#@watchers]

    -- defines non-recursive watchers (eg. only given directories are watched)
    watchnr: (...) =>
      args = {...}
      dirs = [d for i, d in ipairs args when i<#args]
      func = args[#args]
      unless type(func) == 'function'
        error 'last argument to watch must be a setup function'
      @watchers[#@watchers + 1] = Watcher.new dirs, 'create, delete, modify, move, attrib', callback: (w, events) ->
        for e in *events
          @queue\pushright Event.new('fs', e)
      @numnr_dirs += #@watchers[#@watchers].paths
      setfenv func, @handlers
      func!
      @watchers[#@watchers]

    timer: (interval, callback) =>
      @timers[#@timers + 1] = Timer.new interval, callback
      @timers[#@timers]

    -- this is currently a bit dangerous since what one would do on say SIGINT
    -- is probably some cleanup action after which os.exit is called. But what
    -- if someone adds SIGINT and a callback and in some other place the same
    -- thing is done expecting to also run? Need a better way here.
    signal:  (signals, callback) =>
      @signals[#@signals + 1] = Signal.new signals, callback
      @signals[#@signals]

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
          matchers[#matchers + 1] = m
      for matcher in *matchers
        p, f = matcher[1], matcher[2]
        matches = {event.path\match p}
        if #matches > 0
          matching[#matching + 1] = -> f event, unpack(matches)
      matching

  meta
    __call: (func) =>
      setfenv func, @caller_env
      func!
