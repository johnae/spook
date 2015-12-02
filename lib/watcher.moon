colors = require 'ansicolors'
{:log} = _G
{:new_timer, :new_fs_event} = require "uv"
{:is_file} = require "fs"
{:round} = math

run_utility = (changed_file, mapper) ->
  unless is_file changed_file
    log.debug "file deleted: #{changed_file}"
    return

  log.debug "mapping file #{changed_file}..."
  run = mapper changed_file
  if run
    run!
  else
    log.debug "no mapping found for #{changed_file}"

new_handler = (fse, mapper) ->
  local timer
  (handle, filename, events, status) ->
    changed_file = fse\getpath! .. '/' .. filename
    log.debug "changed file #{changed_file}"
    unless timer
      timer = new_timer!
      timer\start 200, 0, ->
        timer\close!
        timer = nil
        run_utility changed_file, mapper

(conf) ->
  {:mapper, :watch} = conf
  for watch_dir in *watch
    fse = new_fs_event!
    handler = new_handler fse, mapper
    fse\start watch_dir, recursive: true, stat: true, handler
