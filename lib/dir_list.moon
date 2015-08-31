fs = require "fs"
insert = table.insert

(top_dirs) ->
  watch_dirs = {}
  for _, dir in ipairs(top_dirs) do
    insert(watch_dirs, dir)
    for entry, attr in fs.dirtree(dir, true) do
      insert watch_dirs, entry if attr.mode == "directory"
  
  watch_dirs
