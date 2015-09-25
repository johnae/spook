local self = debug.getinfo(1).source:match("@(.*)$") 
local base_dir = self:gsub("/run_busted.lua$", "")
_G.arg = {arg[#arg]}

package.path = package.path .. ';spec/support/?.lua'
package.path = package.path .. ';spec/support/?/init.lua'
package.path = package.path .. ';lib/?.lua'
package.path = package.path .. ';lib/?/init.lua'
package.loaded.lfs = require('syscall.lfs')

local moonscript = require "moonscript.base"
package.moonpath = moonscript.create_moonpath(package.path)
local busted = assert(loadfile(base_dir .. '/busted/busted_bootstrap'))
assert(moonscript.loadfile(base_dir .. '/../spec_helper.moon'))()

-- unload everything preloaded
local fs = require("fs")
local entry, attr
for entry, attr in fs.dirtree("lib", true) do
  if entry:match("[^.].moon$") then
    local hndl = (entry:gsub( "%.moon$", "" ):gsub( "^%./", "" ):gsub( "/", "." ):gsub( "\\", "." )):gsub( "%.init$", "" ):gsub("lib%.", "")
    package.preload[hndl] = nil
    package.loaded[hndl] = nil
  end
end
package.loaded.fs = nil
busted()
