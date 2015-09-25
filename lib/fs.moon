lfs = require "syscall.lfs"
remove = table.remove

is_dir = (dir) ->
  return false unless type dir == "string"
  attr = lfs.attributes dir
  return false unless attr and attr.mode == "directory"
  true

is_file = (path) ->
  return false if is_dir path
  f = io.open path, "r"
  if f
    f\close!
    true
  else
    false

dirtree = (dir, recursive) ->
  assert dir and dir != "", "directory parameter is missing or empty"

  if dir\sub(-1) == "/"
    dir = dir\sub 1,-2

  yieldtree = (dir, recursive) ->
    for entry in lfs.dir dir
      if entry != "." and entry != ".."
        entry = "#{dir}/#{entry}"
        attr = lfs.attributes entry
        coroutine.yield entry, attr
        if recursive and attr.mode == "directory"
          yieldtree entry, recursive

  coroutine.wrap -> yieldtree dir, recursive

mkdir_p = (path) ->
  path_elements = path\split "/"
  local dir
  if path_elements[1] == ""
    remove path_elements, 1
    d = remove path_elements, 1
    dir = "/#{d}"
  else
    dir = remove path_elements, 1
  lfs.mkdir dir
  for p in *path_elements
    dir = "#{dir}/#{p}"
    lfs.mkdir dir

rm_rf = (path, attr) ->
    attr = attr or lfs.attributes path
    if attr and attr.mode == "directory"
      for entry, attr in dirtree path, false
        rm_rf entry, attr
      os.remove path
    else if attr
      os.remove path

:dirtree, :rm_rf, :mkdir_p, :is_dir, :is_file
