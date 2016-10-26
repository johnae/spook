{:round} = math
{:log} = _G
gettimeofday = gettimeofday

notify_mt = {
  __index: (k, v) =>
    (name, info={}) ->
      info["#{k}_at"] = gettimeofday! / 1000.0
      for notifier in *@notifiers
        notifier[k] name, info if notifier[k]
}

->
  self = {notifiers: {}}
  self.add = (...) ->
    notifiers = {...}
    for notifier in *notifiers
      if type(notifier) == 'string'
        package.loaded[notifier] = nil -- for proper reloading
        status, result = pcall require, notifier
        unless status
          log.error "Could not find notifier: '#{notifier}' anywhere in the package.path"
          continue
        unless result
          log.error "Failed to load notifier: '#{notifier}'"
          continue
        self.notifiers[#self.notifiers + 1] = result
      else
        self.notifiers[#self.notifiers + 1] = notifier
    self
  self.clear = -> self.notifiers = {}
  setmetatable self, notify_mt
