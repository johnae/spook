export *
moon = require 'moon'
create_file = (file, contents) ->
  f = assert(io.open(file, "w"))
  f\write contents
  f\close!
