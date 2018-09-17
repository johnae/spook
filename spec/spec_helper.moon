export *
moon = require 'moon'
run_loop = (run_once) ->
  (opts={}) ->
    block_for = assert tonumber(opts.block_for), "the block_for key is a required key"
    loops = opts.loops or 1
    duration = opts.duration_ms or 0
    if duration > 0
      start = _G.gettimeofday!
      while (_G.gettimeofday! - start) < duration
        run_once block_for: block_for
    else
      for i=1,loops
        run_once block_for: block_for

create_file = (file, contents) ->
  f = assert(io.open(file, "w"))
  f\write contents
  f\close!
