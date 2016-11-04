package.path = package.path .. ';spec/support/?.lua'
package.path = package.path .. ';spec/support/?/init.lua'
package.path = package.path .. ';lib/?.lua'
package.path = package.path .. ';lib/?/init.lua'
package.path = package.path .. ';vendor/?.lua'
package.path = package.path .. ';vendor/?/init.lua'
package.loaded.lfs = require('syscall.lfs')
local lpeg = require "lpeglj"
package.loaded.lpeg = lpeg
local moonpick = require("moonpick")
local colors = require("ansicolors")

local files = _G.arg
local errors = 0
for _, file in ipairs(files) do
  if file:match('.*%.moon') then
    local res, err = moonpick.lint_file(file)
    if res and #res > 0 then
      io.stdout:write(colors("\n[ %{yellow}LINT warning ]\n%{white}" .. file .. "\n" .. moonpick.format_inspections(res) .. "\n\n"))
      errors = errors + 1
    elseif err then
      io.stdout:write(colors("\n[ %{red}LINT error ]\n%{white}" .. file .. "\n" .. err .. "\n\n"))
      errors = errors + 1
    end
  end
end

if errors > 0 then
  os.exit(1)
end

io.stdout:write(colors("\n[ %{green}LINT: %{white}All good ]\n\n"))
