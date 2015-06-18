package.path = package.path .. ';../deps/luajit/src/jit/?.lua'
package.path = package.path .. ';../src'

local lpeg = require("lpeglj")
package.loaded['lpeg'] = lpeg
local to_lua = require("moonscript.base").to_lua

local args = {...}
local files = {}

local root = args[1]:gsub( "/$", "" )
              :gsub( "\\$", "" )

function luafiles(dir)
  local p = io.popen('find "'..dir..'" -type f -name "*.lua"')
  return p:lines()
end

function moonfiles(dir)
  local p = io.popen('find "'..dir..'" -type f -name "*.moon"')
  return p:lines()
end

function scandir (root, path)
  path = path or ""
  for file in moonfiles( root..path ) do
    local hndl = (file:gsub( "%.moon$", "" ):gsub( "^%./", "" ):gsub( "/", "." ):gsub( "\\", "." )):gsub( "%.init$", "" )
    local content = io.open( file ):read"*a"
    local lua_code, line_table = to_lua(content)
    if not lua_code then
      io.stderr:write("Error in: "..file, "\n")
      io.stderr:write(line_table, "\n")
      os.exit(1)
    end
    files[hndl] = lua_code
  end
  for file in luafiles( root..path ) do
    local hndl = (file:gsub( "%.lua$", "" ):gsub( "^%./", "" ):gsub( "/", "." ):gsub( "\\", "." )):gsub( "%.init$", "" )
    files[hndl] = io.open( file ):read"*a"
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
                       :gsub( "/", "." )
                       :gsub( "\\", "." )
                       :gsub( "%.init$", "" )
      return package.preload[hndl] or original_loadfile( name )
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
