-- The BSD version which is supposed to work on OS X and the BSD:s.
-- It doesn't work fully and the "Watcher" is missing because of several
-- issues with how the kqueue vnode filter works. On OS X I suppose the best
-- would be to use FSEvents (via ffi). I'll leave this as is for the time
-- being. I'll get back to it later.
S = require 'syscall'
Types = S.t
Constants = S.c
:define = require 'classy'
:is_callable = require 'utils'

kqueue_fd = S.kqueue!
timer_id = 0
next_timer_id = ->
  timer_id += 1
  timer_id
EventHandlers = {}
kevs = ->
  events = {}
  for _, v in pairs EventHandlers
    events[#events + 1] = v\__kevdata!
  Types.kevents events

Timer = define 'Timer', ->
  properties
    stopped: => not @started

  instance
    initialize: (interval, callback) =>
      @interval = interval * 1000 -- kqueue takes ms
      @callback = callback
      @ident = next_timer_id! -- NOTE: ident becomes the fd field when receiving event
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

run_once = (opts={}) ->
  process = opts.process or -> nil
  block_for = opts.block_for or 500 -- default 500 ms blocking wait
  block_for = block_for / 1000 -- kqueue takes seconds it seems
  evs = kevs!
  for _, v in kqueue_fd\kevent nil, evs, block_for
    handle = EventHandlers["#{v.filter}_#{v.fd}"]
    handle and handle!
  process!

run = (opts={}) ->
  while true
    run_once opts

clear_all = ->
  for _, v in pairs EventHandlers
    v\stop! if v

:Timer, :Signal, :Read, :kqueue_fd, :run, :run_once, :clear_all
