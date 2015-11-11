(...) ->
  notify = {...}
  setmetatable notify, __index:
    start: (what, data) ->
      for notifier in *notify
        notifier.start what, data
    finish: (status, what, data, elapsed_time) ->
      for notifier in *notify
        notifier.finish status, what, data, elapsed_time
