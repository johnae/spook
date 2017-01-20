-- very simple tool for running in the context of spook
-- run like "luajit run.lua some/file/here.moon"

local file = arg[1]
package.path = package.path .. ';spec/support/?.lua'
package.path = package.path .. ';spec/support/?/init.lua'
package.path = package.path .. ';lib/?.lua'
package.path = package.path .. ';lib/?/init.lua'
package.path = package.path .. ';vendor/?.lua'
package.path = package.path .. ';vendor/?/init.lua'
package.loaded.lfs = require('syscall.lfs')

local lpeg = require'lpeglj'
package.loaded.lpeg = lpeg
require'syscall'
require'moonscript'
local moonscript = require'moonscript.base'
package.moonpath = moonscript.create_moonpath(package.path)

chunk = assert(moonscript.loadfile(file), "Failed to load file: " .. file)
chunk()
