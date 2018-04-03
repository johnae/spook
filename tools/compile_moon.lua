local base_dir = assert(os.getenv("SPOOK_BASE_DIR"), "Please set the env var SPOOK_BASE_DIR to the project directory of spook")
package.path = package.path .. ';' .. base_dir .. '/deps/luajit/src/jit/?.lua'
package.path = package.path .. ';' .. base_dir .. '/vendor/?.lua'
package.path = package.path .. ';' .. base_dir .. '/vendor/?/init.lua'
package.path = package.path .. ';' .. base_dir .. '/lib/?.lua'

local lpeg = require("lpeglj")
package.loaded.lpeg = lpeg
require("moonscript")
local to_lua = require("moonscript.base").to_lua

local args = {...}
local files = {}

local file = args[1]:gsub( "/$", "" )
              :gsub( "\\$", "" )

io.stderr:write("compiling: "..file, "\n")
local basename = (file:gsub( "%.moon$", "" ):gsub( "^%./", "" ):gsub( "/", "." ):gsub( "\\", "." )):gsub( "%.init$", "" )
local f = io.open(file)
local content
if f then
   content = f:read("*a")
   f:close()
else
   error("couldn't open file: " .. file)
end
local lua_code, line_table = to_lua(content)
if not lua_code then
  io.stderr:write("Error in: "..file, "\n")
  io.stderr:write(line_table, "\n")
  os.exit(1)
end
print ( lua_code )
