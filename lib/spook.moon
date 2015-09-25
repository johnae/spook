colors = require 'ansicolors'
{:log} = _G
uv = require "uv"

run_utility = (changed_file, mapper, notifier) ->

  log.debug "mapping file #{changed_file}..."
  run = mapper changed_file

  -- only runs if there is something returned from the "mapper"
  if run
    notifier.start changed_file, run
    successful = run!
    notifier.finish successful, changed_file, run
  else
    log.debug "No mapping found for #{changed_file}"

last_change = {"", true}

create_event_handler = (fse, mapper, notifier) ->
  (self, filename, events, status) ->

    log.debug "change detected"
    changed_file = "#{fse\getpath!}/#{filename}"
    log.debug "changed file #{changed_file}"
    last_change = {changed_file, false}

    timer = uv.new_timer!
    timer\start 200, 0, ->
      timer\close!
      file, recorded = last_change[1], last_change[2]
      last_change[2] = true
      unless recorded
        run_utility changed_file, mapper, notifier

(conf) ->
  {:mapper, :notifier, :watch} = conf

  for watch_dir in *watch
    fse = uv.new_fs_event!
    fse\start watch_dir, {recursive: true, stat: true}, create_event_handler(fse, mapper, notifier)
