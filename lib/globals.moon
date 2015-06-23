{:P, :C, :Ct, :match} = require "lpeg"

ffi = require "ffi"
ffi.cdef [[
char *getcwd(char *buf, size_t size);
]]

split = (str, sep) ->
  sep = P(sep)
  elem = C((1-sep)^0)
  p = Ct(elem * (sep * elem)^0)
  match p, str

_G.getcwd = ->
   buf = ffi.new "char[?]", 1024
   ffi.C.getcwd buf, 1024
   ffi.string buf

_G.project_name = ->
   cwd = split(getcwd!, "/")
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
