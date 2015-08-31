require("vendor")
require("lib")
local lpeg = require("lpeglj")
package.loaded['lpeg'] = lpeg
require("moonscript")
require("globals")
local cli = require("arguments")
local args = cli:parse()
local concat = table.concat
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
  _G.arg = {}
  local loaded_chunk = assert(loadfile(file), "Failed to load file: " .. file)
  loaded_chunk()
else
  -- loading the Spookfile file here (the file mapper)
  local spookfile_path = "Spookfile"
  if args.config then
    spookfile_path = arg.config
  end
  local status, spook_config = load_moonscript(spookfile_path)
  local file_mapping, watch_dirs, notifier_path, command
  if not status then
    log.error("Couldn't load " .. spookfile_path .. ", please create a Spookfile using `spook -i`")
    os.exit(1)
  else
    file_mapping = spook_config.map
    watch_dirs = spook_config.watch
    notifier_path = spook_config.notifier or os.getenv("HOME").."/.spook/notifier.moon"
    command = spook_config.command
  end

  local mapper = require("file_mapper")(file_mapping)

  if args.command and #args.command>0 then
    log.error("parsing command...")
    log.error(args.command)
    log.error(#args.command)
    command = concat(args.command, " ")
  end

  if args.notifier then
    notifier_path = args.notifier_path
  end

  if args.watch then
    watch_dirs = args.watch
  end

  local status, notifier = load_moonscript(notifier_path)
  if not status then
    log.debug("Couldn't load " .. notifier_path .. ", loading default notifier")
    log.debug(notifier)
    notifier = require("default_notifier")
  end

  if watch_dirs then
    watch_dirs = require("dir_list")(watch_dirs)
  else
    watch_dirs = require("stdin_list")()
  end

  local spook = require("spook")
  local runner, watchers = spook(mapper, notifier, command, watch_dirs)
  runner:run()
end
