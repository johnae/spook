local base_dir = assert(os.getenv("SPOOK_BASE_DIR"), "Please set the env var SPOOK_BASE_DIR to the project directory of spook")
package.path = package.path .. ';' .. base_dir .. '/deps/luajit/src/jit/?.lua'
package.path = package.path .. ';' .. base_dir .. '/vendor/?.lua'
package.path = package.path .. ';' .. base_dir .. '/vendor/?/init.lua'
package.path = package.path .. ';' .. base_dir .. '/lib/?.lua'

local lpeg = require("lpeglj")
package.loaded['lpeg'] = lpeg
local function logwrite(...)
   io.stderr:write("LOG: " .. ... .. "\n")
end
package.loaded['log'] = {
   info = logwrite,
   error = logwrite,
   warn = logwrite,
   debug = logwrite
}
require("moonscript")
local to_lua = require("moonscript.base").to_lua
local fs = require("fs")
local moon = require("moon")
local insert = table.insert

local args = {...}
local files = {}

local root = args[1]:gsub( "/$", "" )
              :gsub( "\\$", "" )

function files_with_ext(dir, ext)
  local entry, attr
  local found = {}
  for entry, attr in fs.dirtree(dir, true) do
    if entry:match("[^.]."..ext.."$") then
      insert(found, entry)
    end
  end
  return ipairs(found)
end

function luafiles(dir)
  return files_with_ext(dir, "lua")
end

function moonfiles(dir)
  return files_with_ext(dir, "moon")
end

function should_replace_with_file(str, pat)
  return str:match( "%[%[READ_FILE_(" .. pat .. ")%]%]" )
end

function replace_with_file(str, file, pat)
  local replacement = io.open( file ):read"*a"
  replacement = replacement:gsub("%%", "%%%%")
  return str:gsub ( "%[%[READ_FILE_" .. pat .. "%]%]", "[[" .. replacement .. "]]" )
end

function scandir (root, path)
  path = path or ""
  for i, file in moonfiles( root..path ) do
    io.stderr:write("including: "..file, "\n")
    local hndl = (file:gsub( "%.moon$", "" ):gsub( "^%./", "" ):gsub( "/", "." ):gsub( "\\", "." )):gsub( "%.init$", "" )
    local content = io.open( file ):read"*a"
    local rep = should_replace_with_file( content, ".*%.moon" )
    if rep then
      io.stderr:write("Replacing pattern in " .. file .. " with contents of lib/" .. rep .. "\n")
      content = replace_with_file( content, root .. "/" .. rep, ".*%.moon" )
    end
    local lua_code, line_table = to_lua(content)
    if not lua_code then
      io.stderr:write("Error in: "..file, "\n")
      io.stderr:write(line_table, "\n")
      os.exit(1)
    end
    files[hndl] = lua_code
  end
  for i, file in luafiles( root..path ) do
    local hndl = (file:gsub( "%.lua$", "" ):gsub( "^%./", "" ):gsub( "/", "." ):gsub( "\\", "." )):gsub( "%.init$", "" )
    if not files[hndl] then
      io.stderr:write("including: "..file, "\n")
      files[hndl] = io.open( file ):read"*a"
    else
      io.stderr:write("skipping include of: "..file, " - already present\n")
    end
  end
end

scandir( root )

acc={}

local wrapper = { "\n--------------------------------------\npackage.preload['"
                , nil, "'] = function (...)\n", nil, "\nend\n" }
for k,v in pairs( files ) do
  wrapper[2], wrapper[4] = k, v
  table.insert( acc, table.concat(wrapper) )
end

table.insert(acc, [[
-----------------------------------------------

do
  if not package.__loadfile then
    local original_loadfile = loadfile
    local function lf (file)
      local hndl = file:gsub( "%.lua$", "" )
                       :gsub( "%.moon$", "" )
                       :gsub( "/", "." )
                       :gsub( "\\", "." )
                       :gsub( "%.init$", "" )
      return package.preload[hndl] or original_loadfile( file )
    end

    function dofile (name)
      return lf( name )()
    end

    loadfile, package.__loadfile = lf, loadfile
  end
end
]])
if files.main then table.insert( acc, '\ndofile"main.lua"' ) end
print( table.concat( acc ) )
