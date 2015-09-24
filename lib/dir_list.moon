fs = require "fs"
insert = table.insert

(...) ->
  watch_dirs = {}
  top_dirs = {...}
  for dir in *top_dirs
    if fs.is_dir dir
      insert watch_dirs, dir
      for entry, attr in fs.dirtree dir, true
        insert watch_dirs, entry if attr.mode == "directory"
    else
      log.debug "Specified watch dir \"#{dir}\" is not a directory"
  
  watch_dirs
