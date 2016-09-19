{:round} = math
{:log} = _G
gettimeofday = gettimeofday

->
  notifiers = {}
  {
    add: (notifier) ->
      n = notifier
      if type(n) == 'string'
        status, n = pcall -> require n
        unless n
          log.error "Failed to load notifier: #{notifier}"
          return
      notifiers[#notifiers + 1] = n
    clear: ->
      notifiers = {}
    info: (name, event) ->
      for notifier in *notifiers
        notifier.info name, event if notifier.info
    start: (name, event) ->
      event.started_at = gettimeofday! / 1000.0
      for notifier in *notifiers
        notifier.start name, event if notifier.start
    success: (name, event) ->
      event.ended_at = gettimeofday! / 1000.0
      for notifier in *notifiers
        notifier.success name, event if notifier.success
    fail: (name, event) ->
      event.ended_at = gettimeofday! / 1000.0
      for notifier in *notifiers
        notifier.fail name, event if notifier.fail
  }
