--_G.uv = require "uv"
export *
--
--run_uv_for = (time) ->
--  timer = uv.new_timer!
--  timer\start time, 0, ->
--    timer\stop!
--    timer\close!
--    uv.walk (handle) ->
--      unless handle\is_closing!
--        handle\close!
--    uv\stop!
--  uv\run!
--
create_file = (file, contents) ->
  f = assert(io.open(file, "w"))
  f\write contents
  f\close!
--
--create_file_after = (time, file) ->
--  timer = uv.new_timer!
--  timer\start time, 0, ->
--    f = assert(io.open(file, "w"))
--    f\write("hello")
--    f\close!
--    timer\stop!
--    timer\close!
--
--update_file_after = (time, file) ->
--  timer = uv.new_timer!
--  timer\start time, 0, ->
--    f = assert(io.open(file, "a+"))
--    f\write("update")
--    f\close!
--    timer\stop!
--    timer\close!
--
--delete_file_after = (time, file) ->
--  timer = uv.new_timer!
--  timer\start time, 0, ->
--    os.remove file
--    timer\stop!
--    timer\close!
