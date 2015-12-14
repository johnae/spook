{:is_file} = require "fs"
{:new_timer} = require "uv"

handle_change = (spook, changed_file, mapper) ->
  unless is_file changed_file
    log.debug "file deleted: #{changed_file}"
    return

  log.debug "mapping file #{changed_file}..."
  run = mapper changed_file
  if run
    note, exec = run!
    if type(note) == "table" and exec
      note.changed_file = changed_file
      spook.start note, exec
    else
      log.debug "The handler didn't return the expected response"
      log.debug "Got note of type #{type(note)} and exec of type #{type(exec)}"
      log.debug "Skipping run."
  else
    log.debug "no mapping found for #{changed_file}"

(spook) ->
  changes = {}
  timer = new_timer!
  timer\start 200, 200, ->
    for file, mapper in pairs changes
      changes[file] = nil
      handle_change spook, file, mapper
    spook.clear!
  changes
