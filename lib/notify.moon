gettimeofday = gettimeofday
insert: append = table

notify_mt = {
  __index: (k, v) =>
    (name, info={}) ->
      info["#{k}_at"] = gettimeofday! / 1000.0
      for notifier in *@notifiers
        notifier[k] name, info if notifier[k]
}

->
  self = {notifiers: {}}
  self.add = (notifier) ->
    if type(notifier) == 'string'
      package.loaded[notifier] = nil
      n = require notifier
      append self.notifiers, n
    else
      append self.notifiers, notifier
    self
  self.clear = -> self.notifiers = {}
  setmetatable self, notify_mt
