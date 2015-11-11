colors = require 'ansicolors'
{:log} = _G
{:new_timer, :new_fs_event} = require "uv"
{:is_file} = require "fs"

run_utility = (changed_file, mapper, notifier, deleted) ->

  if deleted
    log.debug "File deleted: #{changed_file}"
    return

  log.debug "mapping file #{changed_file}..."
  run = mapper changed_file

  -- only runs if there is something returned from the "mapper"
  if run
    notifier.start changed_file
    successful = run!
    notifier.finish successful, changed_file
  else
    log.debug "No mapping found for #{changed_file}"

create_event_handler = (fse, mapper, notifier) ->
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
        run_utility changed_file, mapper, notifier, deleted

(conf) ->
  {:mapper, :notifier, :watch} = conf

  for watch_dir in *watch
    fse = new_fs_event!
    fse\start watch_dir, {recursive: true, stat: true}, create_event_handler(fse, mapper, notifier)
