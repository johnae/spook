require("lib")
local lpeg = require("lpeglj")
package.loaded['lpeg'] = lpeg
require("moonscript")
local to_lua = require("moonscript.base").to_lua

local function load_moonscript(file)
  local status, ms = pcall(function()
    local f = io.open(file, "rb")
    local content = f:read("*all")
    f:close()
    local lua_code, line_table = to_lua(content)
    if not lua_code then
      print("Error in " .. file .. " file")
      print(line_table)
    end
    local chunk, err = loadstring(lua_code)
    if err ~= nil then
      print("Error in " .. file .. " file")
      print(err)
    end
    return chunk()
  end)
  return status, ms
end

-- loading the .spook file here (the file mapper)
local status, mapper = load_moonscript(".spook")
if not status then
  mapper = function(file)
    return file
  end
end

-- loading the .notifier file here
local status, notifier = load_moonscript(".spook-notifier")
if not status then
  notifier = function(status)
  end
end

local spook = require("spook")
spook(mapper, notifier)

