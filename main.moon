require "vendor"
require "lib"
lpeg = require "lpeglj"
package.loaded.lpeg = lpeg
require "moonscript"
require "globals"
_G.notify = require("notify")(require "terminal_notifier")
_G.log = require("log")(1)
config = require("config")!
{:run} = require "uv"
moonscript = require "moonscript.base"
{:concat, :remove, :index_of} = table

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

  spookfile_path = "Spookfile"
  if args.config
    spookfile_path = args.config

  conf = config config_file: spookfile_path, args: args
  unless conf
    os.exit 1

  _G.log.level conf.log_level

  colors = require "ansicolors"
  spook = require "spook"
  file_mapper = require "file_mapper"
  dir_list = require "dir_list"

  {:notifiers, :watch} = conf

  for notifier in *notifiers
    notify[#notify + 1] = notifier

  watched = 0
  for dir, on_changed in pairs watch
    dirs = dir_list dir
    watched += #dirs
    mapper = file_mapper on_changed
    spook mapper: mapper, watch: dirs
    
  print colors "[ %{blue}Watching #{watched} directories%{reset} ]"
  print ""
  run!
