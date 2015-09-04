uv = require "uv"
{:insert, :remove, :concat} = table

file_exists = (path) ->
  f = io.open(path, "r")
  if f
    f\close!
    true
  else
    false

run_utility = (changed_file, mapper, notifier, utility) ->

  log.debug "mapping file #{changed_file}..."
  mapped_file, file_utility = mapper(changed_file)

  if file_utility
    log.debug "using matcher utility: #{file_utility}"
    utility = file_utility

  -- only runs if there is something returned from the mapper
  if mapped_file and file_exists mapped_file
    log.debug "mapped file: #{mapped_file}"
    notifier.start changed_file, mapped_file
    log.debug "running: '#{utility} #{mapped_file}'"
    _ ,_ ,status = os.execute "#{utility} #{mapped_file}"
    notifier.finish status, changed_file, mapped_file
  else
    if mapped_file and not file_exists mapped_file
      log.debug "#{mapped_file} does not exist"
    else
      log.debug "No mapping found for #{changed_file}"

last_changed_file = {"", true, 1}

create_event_handler = (fse, mapper, notifier, command) ->
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
        run_utility changed_file, mapper, notifier, command

(mapper, notifier, command, watch_dirs) ->

  log.debug "Command to run "
  log.debug command
  log.info "Watching " .. #watch_dirs .. " directories"

  watchers = {}

  for i, watch_dir in ipairs(watch_dirs) do
    fse = uv.new_fs_event!
    watchers[watch_dir] = fse
    fse\start watch_dir, {recursive: true, stat: true}, create_event_handler(fse, mapper, notifier, command)

  uv, watchers
