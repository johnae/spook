local self = debug.getinfo(1).source:match("@(.*)$") 
local base_dir = self:gsub("/run_busted.lua$", "")
_G.arg = {arg[#arg]}

package.path = package.path .. ';spec/support/?.lua'
package.path = package.path .. ';spec/support/?/init.lua'
package.loaded.lfs = require('syscall.lfs')
local moonscript = require "moonscript.base"
local busted = assert(loadfile(base_dir .. '/busted/busted_bootstrap'))
assert(moonscript.loadfile(base_dir .. '/../spec_helper.moon'))()
busted()
