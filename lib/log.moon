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
      log(level, INFO, "INFO: ", ...)
  
    error: (...) ->
      log(level, ERR, "ERROR: ", ...)
  
    warn: (...) ->
      log(level, WARN, "WARN: ", ...)
  
    debug: (...) ->
      log(level, DEBUG, "DEBUG: ", ...)
  }
