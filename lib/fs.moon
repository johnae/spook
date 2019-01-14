require 'globals'
lfs = require "syscall.lfs"
S = require 'syscall'
log = require'log'
insert: append, :remove = table

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

name_ext = (filename) ->
  name, ext = filename\match '^(.+)(%..*)$'
  return filename unless name
  name, ext

basename = (path) -> path\match "[^/]+$"
dirname = (path) ->
  path = path\gsub '/$', ''
  path\match("^(.*)/.*$") or '.'

remove_trailing_slash = (path) ->
  while path\sub(#path) == "/"
    path = path\sub 1, #path - 1
  path

dirtree = (dir, opts={}) ->
  assert dir and dir != "", "directory parameter is missing or empty"
  dir = remove_trailing_slash dir
  dir = "/" if dir == "" -- was /
  -- be backwards compatible
  if type(opts) == 'boolean'
    opts = recursive: opts
  opts.ignore or= {}

  :recursive, :ignore = opts

  ignores = {'^%.$', '^%.%.$'}
  append(ignores, ign) for ign in *ignore
  ignored = (entry) ->
    for ign in *ignores
      matches = {entry\match ign}
      return true if #matches > 0
    false

  yieldtree = (current_dir) ->
    unless can_access(current_dir)
      log.debug "No access to #{dir}, skipping"
      return
    for entry in lfs.dir current_dir
      continue if ignored(entry)
      entry = "#{remove_trailing_slash(current_dir)}/#{entry}"
      unless can_access(entry)
        log.debug "No access to #{entry}, skipping"
        continue
      attr = lfs.attributes entry
      coroutine.yield entry, attr
      if recursive and attr.mode == "directory"
        yieldtree entry, recursive

  coroutine.wrap -> yieldtree dir

unique_subtrees = (paths, opts={}) ->
  if opts.recursive == nil
    opts.recursive = true
  accessible_dir = (entry, attr) ->
    can_access(entry) and
      ((attr or lfs.attributes(entry)).mode == 'directory')
  recursive_dirmap = (dir) ->
    return {} unless accessible_dir(dir)
    map = { attr.ino, entry for entry, attr in dirtree(dir, opts) when accessible_dir(entry, attr) }
    map[lfs.attributes(dir).ino] = dir
    map

  trees = {}
  for p in *paths
    trees[ino] = entry for ino, entry in pairs recursive_dirmap(p)
  [entry for _, entry in pairs trees]

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

{
  :dirtree,
  :rm_rf,
  :mkdir_p,
  :can_access,
  :is_dir,
  :is_file,
  :is_present,
  :name_ext,
  :basename,
  :dirname,
  :unique_subtrees
}
