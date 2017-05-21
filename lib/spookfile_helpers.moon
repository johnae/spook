log = _G.log
notify = _G.notify

-- Run the same task regardless of fs change
-- until that task succeeds.
local last_task
until_success = (func) ->
  func = last_task if last_task
  last_task = func
  success, result = pcall func
  return error result unless success
  last_task = nil

-- Wraps a command that takes a file
-- as input.
command = (cmd, opts={}) ->
  execute = opts.execute or os.execute
  (file) ->
    cmdline = "#{cmd} #{file}"
    notify.info cmdline
    _, _, status = execute cmdline
    assert status == 0, cmdline

-- For filtering commands not runnable
-- for example when the mapped file does
-- not exist.
task_filter = (filter_func) ->
  (...) ->
    args = {...}
    assert #args > 0 and #args % 2 == 0,
           "a task_filter takes an even number of args larger than zero, got #{#args} args"
    current = 1
    filter = ->
      task, input = args[current], args[current+1]
      current += 2
      return nil unless task and input
      unless filter_func input
        log.debug "Skipping task with input '#{input}' since the filter_func returned false"
        return filter args
      task, input
    filter

-- Runs every task in list, notifying of failure
-- immediately and aborting through error, while
-- notifying of success after all tasks have
-- completed without failure.
notifies = (name, info, list) ->
  run = (func, ...) ->
    success, result = pcall func, ...
    unless success
      notify.fail result, info
      error result
  -- we just get the first here - it may be null
  -- and in that case we don't want to end up
  -- running the success notifier but rather
  -- abort this whole thing
  func, arg = list!
  return unless func
  notify.start name, info
  run func, arg
  run f, a for f, a in list -- so as not to shadow func/arg which linting will complain about
  notify.success name, info

:until_success, :command, :task_filter, :notifies
