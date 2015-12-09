colors = require 'ansicolors'
{:log} = _G
{:new_fs_event} = require "uv"

new_handler = (fse, mapper, changes) ->
  (handle, filename, events, status) ->
    changed_file = fse\getpath! .. '/' .. filename
    log.debug "changed file #{changed_file}"
    changes[changed_file] = mapper

(conf) ->
  {:mapper, :watch, :changes} = conf
  for watch_dir in *watch
    fse = new_fs_event!
    handler = new_handler fse, mapper, changes
    fse\start watch_dir, recursive: false, stat: true, handler
