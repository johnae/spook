require 'globals'
lfs = require "syscall.lfs"
S = require 'syscall'
log = require'log'
:remove = table

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

can_access = (path, mode='r') ->
  return false unless path
  S.access path, mode

dirtree = (dir, recursive) ->
  assert dir and dir != "", "directory parameter is missing or empty"

  if dir\sub(-1) == "/"
    dir = dir\sub 1,-2

  yieldtree = (current_dir) ->
    unless can_access(current_dir)
      log.debug "No access to #{dir}, skipping"
      return
    for entry in lfs.dir current_dir
      if entry != "." and entry != ".."
        entry = "#{current_dir}/#{entry}"
        unless can_access(entry)
          log.debug "No access to #{entry}, skipping"
          continue
        attr = lfs.attributes entry
        coroutine.yield entry, attr
        if recursive and attr.mode == "directory"
          yieldtree entry, recursive

  coroutine.wrap -> yieldtree dir

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
      for entry, nattr in dirtree path, false
        rm_rf entry, nattr
      os.remove path
    else if attr
      os.remove path

:dirtree, :rm_rf, :mkdir_p, :can_access, :is_dir, :is_file, :is_present
