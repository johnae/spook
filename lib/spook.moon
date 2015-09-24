colors = require 'ansicolors'
{:insert, :remove, :concat} = table
{:log} = _G
uv = require "uv"
moon = require "moon"

run_utility = (changed_file, mapper, notifier) ->

  log.debug "mapping file #{changed_file}..."
  run = mapper changed_file

  -- only runs if there is something returned from the change_handler
  if run
    notifier.start changed_file, runnable
    successful = run!
    notifier.finish successful, changed_file, runnable
  else
    log.debug "No mapping found for #{changed_file}"

last_changed_file = {"", true, 1}

create_event_handler = (fse, mapper, notifier) ->
  (self, filename, events, status) ->

    log.debug "change detected"
    changed_file = "#{fse\getpath!}/#{filename}"
    log.debug "changed file #{changed_file}"
    last_changed_file = {changed_file, false, last_changed_file[3]+1}

    timer = uv.new_timer!
    timer\start 200, 0, ->
      timer\close!
      changed_file = last_changed_file[1]
      event_recorded = last_changed_file[2]
      event_id = last_changed_file[3]
      last_changed_file[2] = true
      unless event_recorded
        run_utility changed_file, mapper, notifier

(conf) ->
  {:mapper, :notifier, :watch} = conf

  watchers = {}

  for watch_dir in *watch
    fse = uv.new_fs_event!
    watchers[watch_dir] = fse
    fse\start watch_dir, {recursive: true, stat: true}, create_event_handler(fse, mapper, notifier)

  watchers
