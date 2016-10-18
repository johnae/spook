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

(setup) ->
  self = {notifiers: {}}
  self.add = (notifier) ->
    n = notifier
    if type(n) == 'string'
      package.loaded[n] = nil
      status, n = pcall require, n
      unless n
        log.error "Failed to load notifier: #{notifier}"
        return
    self.notifiers[#self.notifiers + 1] = n
  self.clear = -> self.notifiers = {}
  setmetatable self, notify_mt
  if setup
    setfenv setup, self
    setup!
  self
