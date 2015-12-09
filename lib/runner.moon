{:is_file} = require "fs"
{:new_timer} = require "uv"

run_utility = (changed_file, mapper) ->
  unless is_file changed_file
    log.debug "file deleted: #{changed_file}"
    return

  log.debug "mapping file #{changed_file}..."
  exec = mapper changed_file
  if exec
    exec!
  else
    log.debug "no mapping found for #{changed_file}"

(spook) ->
  changes = {}
  timer = new_timer!
  timer\start 200, 200, ->
    for file, mapper in pairs changes
      changes[file] = nil
      run_utility file, mapper
    spook.clear!
  changes
