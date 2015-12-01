{:round} = math

(...) ->
  notify = {...}
  start = (info) ->
    for notifier in *notify
      notifier.start info if notifier.start
  finish = (success, info) ->
    for notifier in *notify
      notifier.finish success, info if notifier.finish
  setmetatable notify, __index:
    :start
    :finish
    begin: (info, fn) ->
      start_time = gettimeofday! / 1000.0
      start info
      success = fn!
      end_time = gettimeofday! / 1000.0
      info.elapsed_time = round end_time-start_time, 3
      finish success, info
