require("vendor")
require("lib")
local lpeg = require("lpeglj")
package.loaded['lpeg'] = lpeg
require("moonscript")
require("globals")
local cli = require("arguments")
local args = cli:parse()
_G.log = require("log")(args.log_level)

local to_lua = require("moonscript.base").to_lua

local function load_moonscript(file)
  local status, ms = pcall(function()
    local f = io.open(file, "rb")
    local content = f:read("*all")
    f:close()
    local lua_code, line_table = to_lua(content)
    if not lua_code then
      log.error("Error in " .. file .. " file")
      log.error(line_table)
    end
    local chunk, err = loadstring(lua_code)
    if err ~= nil then
      log.error("Error in " .. file .. " file")
      log.error(err)
    end
    return chunk()
  end)
  return status, ms
end

if args.file then
  local file = args.file
  local loaded_chunk = assert(loadfile(file), "Failed to load file: " .. file)
  loaded_chunk()
else
  -- loading the Spookfile file here (the file mapper)
  local spookfile_path = args.mapping or "Spookfile"
  local status, file_mapping = load_moonscript(spookfile_path)
  if not status then
    log.warn("Couldn't load " .. spookfile_path .. ", loading default mapping")
    file_mapping = require("default_file_mapping")
  end

  local mapper = require("file_mapper")(file_mapping)

  -- loading notifier here from ~/.spook/notifier.moon
  local notifier_path = args.notifier or os.getenv("HOME").."/.spook/notifier.moon"
  local status, notifier = load_moonscript(notifier_path)
  if not status then
    log.debug("Couldn't load " .. notifier_path .. ", loading default notifier")
    notifier = require("default_notifier")
  end

  local spook = require("spook")
  spook(mapper, notifier, args)
end
