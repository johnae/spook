{:round} = math
{:log} = _G
gettimeofday = gettimeofday

->
  notifiers = {}
  mt = {
    __index: (k, v) =>
      (name, info={}) ->
        info["#{k}_at"] = gettimeofday! / 1000.0
        for notifier in *notifiers
          notifier[k] name, info if notifier[k]
  }
  note = setmetatable {
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
  }, mt

  {
    :note
    notifies: (name, info, func) ->
      note.start name, info
      success = true
      status, result = pcall -> func!
      success and= status
      return note.fail result, info unless success
      note.success name, info
  }
