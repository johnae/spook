S = require "syscall"
Types = S.t
define = require'classy'.define
{:is_dir, :dirtree} = require 'fs'

kqueue_fd = S.kqueue!
timer_id = 0
EventHandlers = {}
kevs = ->
  events = {}
  for k, v in pairs EventHandlers
    events[#events + 1] = v\__kevdata!
  Types.kevents events

Timer = define 'Timer', ->

  instance
    initialize: (interval, callback) =>
      @interval = interval * 1000 -- kqueue takes ms
      @callback = callback
      timer_id += 1
      @ident = timer_id -- NOTE: ident becomes the fd field when receiving event
      @filter = 'timer'
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
      EventHandlers[@ident] = @
      kqueue_fd\kevent Types.kevents({@__kevdata!}), nil

    stop: =>
      EventHandlers[@ident] = nil
      ev = Types.kevents {@__kevdata(flags: 'delete, oneshot')}
      kqueue_fd\kevent ev, nil

  meta
    __call: =>
      EventHandlers[@ident] = nil
      @callback!

run_once = (opts={}) ->
  process = opts.process or -> nil
  block_for = opts.block_for or 10 -- default 10 ms blocking wait
  block_for = block_for / 1000 -- kqueue takes seconds it seems
  evs = kevs!
  for k, v in kqueue_fd\kevent nil, evs, block_for
    handle = EventHandlers[v.fd] -- timer has an ident, here that is actually the fd
    handle and handle!
  process!

run = (opts={}) ->
  while true
    run_once opts

:Timer, :kqueue_fd, :run, :run_once
