package.path = package.path .. ';spec/support/?.lua'
package.path = package.path .. ';spec/support/?/init.lua'
package.path = package.path .. ';lib/?.lua'
package.path = package.path .. ';lib/?/init.lua'
package.path = package.path .. ';vendor/?.lua'
package.path = package.path .. ';vendor/?/init.lua'
package.loaded.lfs = require('syscall.lfs')
local lpeg = require "lpeglj"
package.loaded.lpeg = lpeg
local lint = require("moonscript.cmd.lint").lint_file
local colors = require("ansicolors")

local files = _G.arg
local lint_error = false
for idx, file in ipairs(files) do
  if file:match('.*%.moon') then
    local result, err
    result, err = lint(file)
    if result ~= nil then
      lint_error = true
      io.stdout:write(colors("\n[ %{red}LINT error ]\n%{white}" .. result .. "\n\n"))
    elseif err ~= nil then
      lint_error = true
      io.stdout:write(colors("\n[ %{red}LINT error ]\n%{white}" .. file .. "\n" .. err .. "\n\n"))
    end
  end
end

if lint_error == true then
  os.exit(1)
end

io.stdout:write(colors("\n[ %{green}LINT: %{white}All good ]\n\n"))
os.exit(0)
