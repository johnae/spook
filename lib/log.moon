serpent = require 'serpent'

format = (p) ->
  if type(p) == 'table'
    return serpent.block p, comment: false, sortkeys: true
  p

local logger

logger = (...) -> print ...

log = (req_level, level, ...) ->
  if req_level >= level
    params = [format(v) for v in *{...}]
    logger unpack params

ERR = 0
WARN = 1
INFO = 2
DEBUG = 3

log_level = INFO
{
  :ERR
  :WARN
  :INFO
  :DEBUG

  logger: (f) ->
    logger = f

  level: (l) ->
    log_level = l

  info: (...) ->
    log(log_level, INFO, ...)

  error: (...) ->
    log(log_level, ERR, ...)

  warn: (...) ->
    log(log_level, WARN, ...)

  debug: (...) ->
    log(log_level, DEBUG, ...)
}
