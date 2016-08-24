lfs = require "syscall.lfs"
remove = table.remove

is_dir = (dir) ->
  return false unless type(dir) == "string"
  attr = lfs.attributes dir
  return false unless attr and attr.mode == "directory"
  true

is_file = (path) ->
  return false if is_dir path
  return false unless type(path) == "string"
  f = io.open path, "r"
  if f
    f\close!
    true
  else
    false

is_present = (path) ->
  is_dir(path) or is_file(path)

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

dir_table = (dir) ->
  tbl = {}
  for entry, attr in dirtree dir
    path = entry\split('/')
    name = path[#path]
    if attr.mode == "directory"
      tbl[name] = dir_table entry
    else
      tbl[name] = true
  tbl

dir_diff = (a, b) ->
  d = {}
  a or= {}
  b or= {}
  for k,v in pairs(a)
    if type(v) == "table"
      d[k] = dir_diff v, b[k]
    else
      unless b[k]
        d[k] = "DELETED"
  for k,v in pairs(b)
    if type(v) == "table"
      d[k] = dir_diff a[k], v
    else
      unless a[k]
        d[k] = "CREATED"
  d

:dirtree, :rm_rf, :mkdir_p, :is_dir, :is_file, :is_present, :dir_table, :dir_diff
