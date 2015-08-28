uv = require "uv"
{:insert, :remove, :concat} = table

file_exists = (path) ->
  f = io.open(path, "r")
  if f
    f\close!
    true
  else
    false

print_line = (line) ->
  io.write line
  io.write "\n"
  io.flush!

run_utility = (changed_file, mapper, notifier, utility) ->
  mapped_file = mapper(changed_file)
  -- only runs if there is something returned from the mapper
  if mapped_file and file_exists mapped_file
    log.debug "mapped file: #{mapped_file}"
    notifier.start changed_file, mapped_file
    output = io.popen "#{utility} #{mapper(changed_file)}"
    while true do
      line = output\read!
      break unless line
      print_line line

    rc = {output\close!}
    notifier.finish rc[3], changed_file, mapped_file
  else
    if mapped_file and not file_exists mapped_file
      log.debug "#{mapped_file} does not exist"
    else
      log.debug "No mapping found for #{changed_file}"

last_changed_file = {"", true, 1}

create_event_handler = (fse, mapper, notifier, command) ->
  (self, filename, events, status) ->
    changed_file = "#{fse\getpath!}/#{filename}"
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

(mapper, notifier, args, watch_dirs) ->
  command_segments = [item for i, item in ipairs(args.command) when i > 1]

  if #command_segments == 0
    log.error "No command given, please supply the command on the command line as the last argument(s), something like: ", "\n"
    log.error "find dir1 dir2 -type d | spook rspec -f d"
    os.exit 1

  command = concat command_segments, ' '
  log.info "Watching " .. #watch_dirs .. " directories"

  watchers = {}

  for i, watch_dir in ipairs(watch_dirs) do
    fse = uv.new_fs_event!
    watchers[watch_dir] = fse
    fse\start watch_dir, {recursive: true, stat: true}, create_event_handler(fse, mapper, notifier, command)

  uv, watchers
