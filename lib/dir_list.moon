fs = require "fs"
insert = table.insert

(top_dirs) ->
  watch_dirs = {}
  for _, dir in ipairs(top_dirs) do
    if fs.is_dir(dir)
      insert(watch_dirs, dir)
      for entry, attr in fs.dirtree(dir, true) do
        insert watch_dirs, entry if attr.mode == "directory"
    else
      log.debug "Specified watch dir \"#{dir}\" is not a directory"
  
  watch_dirs
