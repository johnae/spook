package.path = package.path .. ';spec/support/?.lua'
package.path = package.path .. ';spec/support/?/init.lua'
package.path = package.path .. ';lib/?.lua'
package.path = package.path .. ';lib/?/init.lua'
package.loaded.lfs = require('syscall.lfs')
lint = require("moonscript.cmd.lint").lint_file
lfs = require("lfs")

files = _G.arg
lint_error = false
for file in *files
  result, err = lint file
  if result
    lint_error = true
    io.stdout\write "#{result}\n\n"
  elseif err
    lint_error = true
    io.stdout\write "#{file}\n#{err}\n\n"

if lint_error
  os.exit 1
else
  os.exit 0
