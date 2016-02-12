package.path = package.path .. ';spec/support/?.lua'
package.path = package.path .. ';spec/support/?/init.lua'
package.path = package.path .. ';lib/?.lua'
package.path = package.path .. ';lib/?/init.lua'
package.loaded.lfs = require('syscall.lfs')
lint = require("moonscript.cmd.lint").lint_file
moonscript = require "moonscript.base"
colors = require("ansicolors")
local lint_config
pcall -> lint_config = moonscript.loadfile("lint_config.moon")!

files = _G.arg
lint_error = false
for file in *files
  result, err = lint file
  if result
    lint_error = true
    io.stdout\write colors("\n[ %{red}LINT error ]\n%{white}#{result}\n\n")
  elseif err
    lint_error = true
    io.stdout\write colors("\n[ %{red}LINT error ]\n#%{white}{file}\n#{err}\n\n")

if lint_error
  os.exit 1
else
  io.stdout\write colors("\n[ %{green}LINT: %{white}All good ]\n\n")
  os.exit 0
