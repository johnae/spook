{:floor} = math

S = require 'syscall'
ffi = require 'ffi'

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
g_timeval = ffi.new("struct timeval")
gettimeofday = ->
  S.gettimeofday(g_timeval)
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
