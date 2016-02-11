-- load the core
require "vendor"
require "lib"
lpeg = require "lpeglj"
package.loaded.lpeg = lpeg
require "globals"

-- add some default load paths
package.path = package.path .. ";#{getcwd!}/.spook/lib/?.lua"
package.path = package.path .. ";#{getcwd!}/.spook/lib/?/init.lua"
package.path = package.path .. ";#{os.getenv('HOME')}/.spook/lib/?.lua"
package.path = package.path .. ";#{os.getenv('HOME')}/.spook/lib/?/init.lua"

-- setup additional requirements
require "moonscript"
_G.log = require("log")(1)
_G.notify = require("notify")!
_G.spook = require("spook")(notify)
config = require("config")!
{:run} = require "uv"
moonscript = require "moonscript.base"
{:index_of} = table

if fi = index_of arg, "-f"
  file = arg[fi + 1]
  new_args = [a for i, a in ipairs arg when i>(fi + 1)]
  unless file
    log.error "The -f option requires an argument"
    os.exit 1
  _G.arg = new_args
  loaded_chunk = if file\match "[^.]%.lua$"
    assert loadfile(file), "Failed to load file: #{file}"
  else -- assume it's moonscript
    assert moonscript.loadfile(file), "Failed to load file: #{file}"
  loaded_chunk!

else
  cli = require "arguments"
  args = cli\parse!

  spookfile_path = args.config or "Spookfile"

  if args.log_level
    _G.log.level assert tonumber(args.log_level) or _G.log[args.log_level]

  conf = config config_file: spookfile_path, args: args
  unless conf
    os.exit 1

  unless args.log_level
    _G.log.level conf.log_level

  colors = require "ansicolors"
  watcher = require "watcher"
  worker = require "worker"
  file_mapper = require "file_mapper"
  dir_list = require "dir_list"

  {:notifiers, :watch} = conf

  for notifier in *notifiers
    notify[#notify + 1] = notifier

  watched = 0
  changes = worker spook
  for dir, on_changed in pairs watch
    dirs = dir_list dir
    watched += #dirs
    mapper = file_mapper on_changed
    watcher mapper: mapper, watch: dirs, :changes

  print colors "[ %{blue}Watching #{watched} directories%{reset} ]"
  print ""
  run!
