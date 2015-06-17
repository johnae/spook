package.path = package.path .. ';../deps/luajit/src/jit/?.lua' 
args = {...}
files = {}

root = args[1]:gsub( "/$", "" )
              :gsub( "\\$", "" )

function luafiles(dir)
   local p = io.popen('find "'..dir..'" -type f -name "*.lua"')
   return p:lines()
end

function scandir (root, path)
  path = path or ""
  for file in luafiles( root..path ) do
    hndl = (file:gsub( "%.lua$", "" ):gsub( "^%./", "" ):gsub( "/", "." ):gsub( "\\", "." )):gsub( "%.init$", "" )
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
