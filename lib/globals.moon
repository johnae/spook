{:floor} = math

S = require "syscall"
ffi = require "ffi"

pattern_escapes = {
  "(": "%(",
  ")": "%)",
  ".": "%.",
  "%": "%%",
  "+": "%+",
  "-": "%-",
  "*": "%*",
  "?": "%?",
  "[": "%[",
  "]": "%]",
  "^": "%^",
  "$": "%$",
  "\0": "%z"
}

escape_pattern = (str) -> str\gsub(".", pattern_escapes)

export *

string.split = (str, delim) ->
  return {} if str == ""
  str ..= delim
  delim = escape_pattern(delim)
  [m for m in str\gmatch("(.-)"..delim)]

table.index_of = (t, v) ->
  for i = 1, #t
    return i if t[i] == v
  nil

table.merge = (t1, t2) ->
  res = {k, v for k, v in pairs t1}
  for k, v in pairs t2
    res[k] = v
  res

table.empty = (t) ->
  unless next(t)
    return true
  false

math.round = (num, dp) ->
  m = 10 ^ (dp or 0)
  floor( num * m + 0.5 ) / m

local g_timeval
_gettimeofday = S.gettimeofday
gettimeofday = ->
  g_timeval or= ffi.new("struct timeval")
  _gettimeofday(g_timeval)
  tonumber((g_timeval.tv_sec * 1000) + (g_timeval.tv_usec / 1000))

getcwd = S.getcwd

_chdir = S.chdir
chdir = (path, f) ->
  cwd = getcwd!
  r = _chdir path
  if f
    f!
    _chdir cwd
  r

project_name = ->
  cwd = getcwd!\split("/")
  cwd[#cwd]

git_branch = ->
  b = io.popen "git symbolic-ref --short HEAD"
  branch = b\read "*a"
  b\close!
  branch

git_tag = ->
  t = io.popen "git tag -l --contains HEAD"
  tag = t\read "*a"
  t\close!
  return nil if tag == ""
  tag

git_sha = ->
  s = io.popen "git rev-parse --short HEAD"
  sha = s\read "*a"
  s\close!
  sha

git_ref = ->
  git_tag! or git_branch!
