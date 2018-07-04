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

is_symlink = (path) ->
  lattr, err = lfs.symlinkattributes(entry)
  return false if err
  lattr.mode == "link"

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
  recursive = opts.recursive or false
  filters = {can_access}
  if opts.filters
    for filter in *opts.filters
      append filters, filter
  path_filter = (path) ->
    for filter in *filters
      unless filter(path)
        log.debug "#{path} is skipped because of filter"
        return false
    true

  yieldtree = (current_dir) ->
    return unless path_filter(current_dir)
    for entry in lfs.dir current_dir
      if entry != "." and entry != ".."
        entry = "#{remove_trailing_slash(current_dir)}/#{entry}"
        continue unless path_filter(entry)
        attr = lfs.attributes entry
        coroutine.yield entry, attr
        if recursive and attr.mode == "directory"
          yieldtree entry, recursive

  coroutine.wrap -> yieldtree dir

unique_subtrees = (paths, follow_links = true) ->
  is_not_symlink = (path) -> not is_symlink(path)
  filters = {}
  unless follow_links
    append filters, is_not_symlink
  accessible_dir = (entry, attr) ->
    can_access(entry) and
      ((attr or lfs.attributes(entry)).mode == 'directory')
  recursive_dirmap = (dir) ->
    return {} unless accessible_dir(dir)
    map = { attr.ino, entry for entry, attr in dirtree(dir, :filters, recursive: true) when accessible_dir(entry, attr) }
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
      for entry, nattr in dirtree path, recursive: false
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
  :is_symlink,
  :name_ext,
  :basename,
  :dirname,
  :unique_subtrees
}
