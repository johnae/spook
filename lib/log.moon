log = (req_level, level, ...) ->
  if req_level >= level
    params = [v for v in *{...}]
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
