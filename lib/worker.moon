{:is_file} = require "fs"
{:new_timer} = require "uv"
log = _G.log

RUNS = {}

handle_change = (changed_file, mapper) ->
  unless is_file changed_file
    log.debug "file deleted: #{changed_file}"
    return

  log.debug "mapping file #{changed_file}..."
  rule = mapper changed_file
  if rule
    runner = rule!
    if runner
      id = runner.id changed_file
      if not RUNS[id]
        RUNS[id] = true
        runner changed_file
      else
        log.debug "Skipping run for id #{id} - last run too recent"

    else
      log.debug "The handler didn't return the expected response"
      log.debug "Got runner of type #{type(runner)}"
      log.debug "Skipping run."
  else
    log.debug "no mapping found for #{changed_file}"

->
  changes = {}
  timer = new_timer!
  timer\start 200, 200, ->
    for file, mapper in pairs changes
      changes[file] = nil
      handle_change file, mapper
    for run, _ in pairs RUNS
      RUNS[run] = nil
  changes
