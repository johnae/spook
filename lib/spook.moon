colors = require 'ansicolors'
{:log} = _G
{:new_timer, :new_fs_event} = require "uv"
{:is_file} = require "fs"
{:round} = math

run_utility = (changed_file, mapper, deleted) ->

  if deleted
    log.debug "file deleted: #{changed_file}"
    return

  log.debug "mapping file #{changed_file}..."
  run = mapper changed_file
  run and run! or log.debug "no mapping found for #{changed_file}"

create_event_handler = (fse, mapper) ->
  local changed_file, timer
  (handle, filename, events, status) ->

    changed_file = "#{fse\getpath!}/#{filename}"
    log.debug "changed file #{changed_file}"

    unless timer
      timer = new_timer!
      timer\start 100, 0, ->
        timer\close!
        timer = nil
        deleted = not is_file changed_file
        run_utility changed_file, mapper, deleted

(conf) ->
  {:mapper, :watch} = conf
  for watch_dir in *watch
    fse = new_fs_event!
    fse\start watch_dir, {recursive: true, stat: true}, create_event_handler(fse, mapper)
