uv = require "uv"
{:insert, :remove, :concat} = table

watch_dirs = {}
for line in io.lines! do
  line, _ = line\gsub "/$", "", 1
  insert watch_dirs, line

arg_copy = {k,v for k,v in pairs arg}
remove arg_copy, 1

utility = nil
if #arg_copy >= 1
  utility = concat arg_copy, ' '

file_exists = (path) ->
  f = io.open(path, "r")
  if f
    f\close!
    true
  else
    false

run_utility = (changed_file, mapper, notifier) ->
  unless utility
    print "No utility to run on file changes, please supply it via arguments"
    return false

  mapped_file = mapper(changed_file)
  -- only runs if there is something returned from the mapper
  if mapped_file and file_exists mapped_file
    notifier.start changed_file, mapped_file
    output = io.popen "#{utility} #{mapper(changed_file)}"
    while true do
      line = output\read!
      break unless line
      io.write line
      io.write "\n"
      io.flush!

    rc = {output\close!}
    notifier.finish rc[3], changed_file, mapped_file

last_changed_file = {"", true, 1}

create_event_handler = (fse, mapper, notifier) ->
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
        run_utility changed_file, mapper, notifier

(mapper, notifier) ->
  print "Watching " .. #watch_dirs .. " directories"
  for i, watch_dir in ipairs(watch_dirs) do
    fse = uv.new_fs_event!
    fse\start watch_dir, {recursive: true, stat: true}, create_event_handler(fse, mapper, notifier)

  uv.run!
