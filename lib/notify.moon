{:round} = math

(...) ->
  notify = {...}
  start = (what, data) ->
    for notifier in *notify
      notifier.start what, data
  finish = (status, what, data, elapsed_time) ->
    for notifier in *notify
      notifier.finish status, what, data, elapsed_time
  setmetatable notify, __index:
    :start
    :finish
    begin: (what, data, fn) ->
      start_time = gettimeofday! / 1000.0
      start what, data
      success = fn!
      end_time = gettimeofday! / 1000.0
      elapsed = round end_time-start_time, 3
      finish success, what, data, elapsed
