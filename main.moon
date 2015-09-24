require "vendor"
require "lib"
lpeg = require "lpeglj"
package.loaded.lpeg = lpeg
require "moonscript"
require "globals"
config = require("config")!
uv = require "uv"
moonscript = require "moonscript.base"
{:concat, :remove, :index_of} = table

if fi = index_of arg, "-f"

  file = arg[fi + 1]
  new_args = [a for i, a in ipairs arg when i>(fi + 1)]
  unless file
    log.error "The -f option requires an argument"
    os.exit 1
  _G.arg = new_args
  _G.log = require("log")(1)
  loaded_chunk = assert loadfile(file), "Failed to load file: #{file}"
  loaded_chunk!

else

  cli = require "arguments"
  args = cli\parse!

  spookfile_path = "Spookfile"
  if args.config
    spookfile_path = args.config

  conf = config config_file: spookfile_path, args: args
  if not conf
    os.exit 1

  _G.log = require("log")(conf.log_level)

  colors = require 'ansicolors'
  spook = require "spook"
  file_mapper = require "file_mapper"
  dir_list = require "dir_list"

  {:notifier, :show_command, :watch} = conf

  watched = 0
  for dir, conf in pairs watch
    dirs = dir_list dir
    watched += #dirs
    mapper = file_mapper conf.map
    spook {mapper: mapper, command: conf.command,
          notifier: notifier, watch: dirs, show_command: show_command}
    
  log.info colors("%{blue}Watching " .. watched .. " directories")
  uv\run!
