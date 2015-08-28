fs = require "fs"
insert = table.insert

(top_dirs) ->
  watch_dirs = top_dirs
  for _, dir in ipairs(top_dirs) do
    for entry, attr in fs.dirtree(dir, true) do
      insert watch_dirs, entry if attr.mode == "directory"
  
  watch_dirs
