require("vendor")
require("lib")
local lpeg = require("lpeglj")
package.loaded['lpeg'] = lpeg
require("moonscript")
require("globals")
local cli = require("arguments")
local moonscript = require("moonscript.base")

local concat = table.concat
local remove = table.remove

function run_file()
  for i,v in pairs(arg) do
    if v == "-f" then
      remove(arg, i)
      file = remove(arg, i)
      _G.arg[0] = nil
      return true, file
    end
  end
  return false, nil
end

local run_file, file = run_file()

if run_file then

  _G.log = require("log")(1)
  local loaded_chunk = assert(loadfile(file), "Failed to load file: " .. file)
  loaded_chunk()

else

  local args = cli:parse()
  _G.log = require("log")(args.log_level)
  local file_mapping, watch_dirs, notifier_path, command
  local spookfile_path = "Spookfile"

  if args.config then
    spookfile_path = args.config
  end

  local spook_config = assert(moonscript.loadfile(spookfile_path))()
  if not spook_config then
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
    log.debug("parsing command...")
    log.debug(args.command)
    log.debug(#args.command)
    command = concat(args.command, " ")
  end

  if args.notifier then
    notifier_path = args.notifier
  end

  if args.watch then
    watch_dirs = args.watch
  end

  local status, notifier = pcall(function() return moonscript.loadfile(notifier_path)() end)
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
  local runner, watchers = spook(mapper, notifier, command, watch_dirs, args)
  runner:run()
end
