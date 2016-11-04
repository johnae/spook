-- The BSD version which is supposed to work on OS X and the BSD:s.
-- It doesn't work fully and the "Watcher" is missing because of several
-- issues with how the kqueue vnode filter works. On OS X I suppose the best
-- would be to use FSEvents (via ffi). I'll leave this as is for the time
-- being. I'll get back to it later.
S = require "syscall"
Types = S.t
Constants = S.c
define = require'classy'.define

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

  instance
    initialize: (interval, callback) =>
      @interval = interval * 1000 -- kqueue takes ms
      @callback = callback
      @ident = next_timer_id! -- NOTE: ident becomes the fd field when receiving event
      @filter = 'timer'
      @filter_num = Constants.EVFILT[@filter]
      @flags = 'add, oneshot'
      @data = @interval
      assert type(@callback) == 'function', "'callback' is required for a timer and must be a callable object (like a function)"

    __kevdata: (opts={}) =>
      :flags, :data = opts
      :ident, :filter = @
      flags or= @flags
      data or= @data
      :ident, :filter, :flags, :data

    start: =>
      @stop!
      @again!

    again: =>
      EventHandlers["#{@filter_num}_#{@ident}"] = @
      kqueue_fd\kevent Types.kevents({@__kevdata!})

    stop: =>
      EventHandlers["#{@filter_num}_#{@ident}"] = nil
      ev = Types.kevents {@__kevdata(flags: 'delete, oneshot')}
      kqueue_fd\kevent ev

  meta
    __call: =>
      EventHandlers["#{@filter_num}_#{@ident}"] = nil
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
  instance
    initialize: (signal, callback) =>
      @callback = callback
      @signal = signal
      @filter = 'signal'
      @filter_num = Constants.EVFILT[@filter]
      @ident = Constants.SIG[@signal]
      @flags = 'add'
      assert type(@callback) == 'function', "'callback' is required for a timer and must be a callable object (like a function)"

    __kevdata: (opts={}) =>
      :flags = opts
      :signal, :filter = @
      flags or= @flags
      :filter, :flags, :signal

    start: =>
      EventHandlers["#{@filter_num}_#{@ident}"] = @
      signalblock @signal
      kqueue_fd\kevent Types.kevents({@__kevdata!})

    stop: =>
      EventHandlers["#{@filter_num}_#{@ident}"] = nil
      signalunblock @signal
      kqueue_fd\kevent Types.kevents {@__kevdata(flags: 'delete')}

  meta
    __call: =>
      @callback!

Read = define 'Read', ->
  instance
    initialize: (fd, callback) =>
      @fdnum = type(fd) == 'number' and fd or fd\getfd!
      @callback = callback
      @filter = 'read'
      @filter_num = Constants.EVFILT[@filter]
      @flags = 'add'
      assert type(@callback) == 'function', "'callback' is required for a signal and must be a callable object (like a function)"

    __kevdata: (opts={}) =>
      :flags = opts
      :filter = @
      flags or= @flags
      :filter, :flags, fd: @fdnum

    start: =>
      EventHandlers["#{@filter_num}_#{@fdnum}"] = @
      kqueue_fd\kevent Types.kevents({@__kevdata!}), nil

    stop: =>
      EventHandlers["#{@filter_num}_#{@fdnum}"] = nil
      kqueue_fd\kevent Types.kevents {@__kevdata(flags: 'delete')}

  meta
    __call: =>
      input = S.read @fdnum
      @callback input

Stdin = define 'Stdin', ->
  parent Read
  instance
   initialize: (callback) =>
     super @, 0, callback

run_once = (opts={}) ->
  process = opts.process or -> nil
  block_for = opts.block_for or 10 -- default 10 ms blocking wait
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

:Timer, :Signal, :Read, :Stdin, :kqueue_fd, :run, :run_once, :clear_all
