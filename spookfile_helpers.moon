log = _G.log

(notify) ->
  local last_task
  until_success = (func) ->
    func = last_task if last_task
    last_task = func
    success, result = pcall func
    return error result unless success
    last_task = nil

  command = (cmd) ->
    (file) ->
      cmdline = "#{cmd} #{file}"
      notify.info cmdline
      _, _, status = os.execute cmdline
      assert status == 0, cmdline

  -- This is so that one can filter
  -- out commands not runnable (like when
  -- the mapped file doesn't exist)
  task_filter = (filter_func) ->
    (...) ->
      args = {...}
      assert #args > 0 and #args % 2 == 0,
             "a task_filter takes an even number of args larger than zero, got #{#args} args"
      current = -1
      ->
        current += 2
        while args[current+1] and not filter_func(args[current+1])
          log.debug "Skipping #{args[current+1]} since the filter_func function returned false"
          current += 2
        args[current], args[current+1]

  notifies = (name, info, list) ->
    run = (func, ...) ->
      success, result = pcall func, ...
      unless success
        notify.fail result, info
        error result
    func, arg = list!
    return unless func
    notify.start name, info
    run func, arg
    run func, arg for func, arg in list
    notify.success name, info

  :until_success, :command, :task_filter, :notifies
