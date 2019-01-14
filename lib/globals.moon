:floor = math

S = require 'syscall'
ffi = require 'ffi'
insert: append, :concat = table

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

string.escape_pattern = escape_pattern

string.split = (str, delim) ->
  return {} if str == ""
  if delim == nil or delim == ''
    return [m for m in str\gmatch(".")]
  str ..= delim
  delim = escape_pattern(delim)
  [m for m in str\gmatch("(.-)"..delim)]

string.trim = (str) ->
  t = str\match "^%s*()"
  t > #str and "" or str\match(".*%S", t)

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

table.clear = (t) ->
  for k in next, t
    t[k] = nil

take_while = (func) ->
  keep = true
  (...) ->
    keep and= func(...)
    keep

drop_while = (func) ->
  t = take_while func
  (...) -> not t(...)

math.round = (num, dp) ->
  m = 10 ^ (dp or 0)
  floor( num * m + 0.5 ) / m

g_timeval = ffi.new("struct timeval")
gettimeofday = ->
  S.gettimeofday(g_timeval)
  tonumber((g_timeval.tv_sec * 1000) + (g_timeval.tv_usec / 1000))

getcwd = S.getcwd

_chdir = S.chdir
chdir = (path, f) ->
  cwd = getcwd!
  r = _chdir path
  fret = {}
  if f
    fret = {f(r)}
    _chdir cwd
  r, unpack(fret)

timer = (name) ->
  ts = gettimeofday!
  (func) ->
    func or= print
    func "#{name} completed in #{gettimeofday!-ts}ms"

moonscript = require "moonscript.base"
fileload = (file) ->
  is_lua = file\match "[^.]%.lua$"
  lines = {}
  shebang = true
  for line in io.lines(file)
    continue if shebang and line\match '^#!.*$'
    shebang = false
    append lines, line
  if is_lua
    pcall loadstring, (concat lines, "\n")
  else
    pcall moonscript.loadstring, (concat lines, "\n")