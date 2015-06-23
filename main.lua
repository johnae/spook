require("vendor")
require("lib")
local lpeg = require("lpeglj")
package.loaded['lpeg'] = lpeg
require("moonscript")
require("globals")
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

-- loading the Spookfile file here (the file mapper)
local status, file_mapping = load_moonscript("Spookfile")
if not status then
  file_mapping = require("default_file_mapping")
end

local mapper = require("file_mapper")(file_mapping)

-- loading notifier here from ~/.spook/notifier.moon
local status, notifier = load_moonscript(os.getenv("HOME").."/.spook/notifier.moon")
if not status then
  notifier = require("default_notifier")
end

local spook = require("spook")
spook(mapper, notifier)

