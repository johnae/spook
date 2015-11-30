{:dirtree, :is_dir} = require "fs"

(...) ->
  watch_dirs = {}
  top_dirs = {...}
  for dir in *top_dirs
    if is_dir dir
      watch_dirs[#watch_dirs + 1] = dir
      for entry, attr in dirtree dir, true
        watch_dirs[#watch_dirs + 1] = entry if attr.mode == "directory"
    else
      log.debug "Specified watch dir \"#{dir}\" is not a directory"
  
  watch_dirs
