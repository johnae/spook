insert = table.insert
->
  watch_dirs = {}
  for line in io.lines!
    line, _ = line\gsub "/$", "", 1
    insert watch_dirs, line
  
  watch_dirs
