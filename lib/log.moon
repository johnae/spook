serpent = require 'serpent'

format = (p) ->
  if type(p) == 'table'
    return serpent.block p, comment: false, sortkeys: true

  p

log = (req_level, level, ...) ->
  if req_level >= level
    params = [format(v) for v in *{...}]
    print unpack(params)

ERR = 0
WARN = 1
INFO = 2
DEBUG = 3

(level) ->
  {
    info: (...) ->
      log(level, INFO, ...)
  
    error: (...) ->
      log(level, ERR, ...)
  
    warn: (...) ->
      log(level, WARN, ...)
  
    debug: (...) ->
      log(level, DEBUG, ...)
  }
