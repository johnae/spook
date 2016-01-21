{:floor} = math

ffi = require "ffi"
ffi.cdef [[
char *getcwd(char *buf, size_t size);
int chdir(const char *path);
]]

ffi_C = ffi.C

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

math.round = (num, dp) ->
  m = 10 ^ (dp or 0)
  floor( num * m + 0.5 ) / m

local g_timeval
_G.gettimeofday = ->
  g_timeval or= ffi.new("struct timeval")
  ffi_C.gettimeofday g_timeval, nil
  tonumber((g_timeval.tv_sec * 1000) + (g_timeval.tv_usec / 1000))

_G.getcwd = ->
  buf = ffi.new "char[?]", 1024
  ffi_C.getcwd buf, 1024
  ffi.string buf

_G.chdir = (path, f) ->
  cwd = getcwd!
  r = ffi_C.chdir path
  if f
    f!
    ffi_C.chdir cwd
  r

_G.project_name = ->
  cwd = getcwd!\split("/")
  cwd[#cwd]

_G.git_branch = ->
  b = io.popen "git symbolic-ref --short HEAD"
  branch = b\read "*a"
  b\close!
  branch

_G.git_tag = ->
  t = io.popen "git tag -l --contains HEAD"
  tag = t\read "*a"
  t\close!
  return nil if tag == ""
  tag

_G.git_sha = ->
  s = io.popen "git rev-parse --short HEAD"
  sha = s\read "*a"
  s\close!
  s

_G.git_ref = ->
  git_tag! or git_branch!
