require "vendor"
require "lib"
lpeg = require "lpeglj"
package.loaded.lpeg = lpeg
require "moonscript"
require "globals"
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
  _G.log = require("log")(args.log_level)
  local file_mapping, watch_dirs, notifier_path, command

  spookfile_path = "Spookfile"
  if args.config
    spookfile_path = args.config

  spook_config = assert(moonscript.loadfile(spookfile_path))()
  if not spook_config
    log.error "Couldn't load #{spookfile_path}, please create a Spookfile using `spook -i`"
    os.exit 1
  else
    file_mapping = spook_config.map
    watch_dirs = spook_config.watch
    notifier_path = spook_config.notifier or "#{os.getenv('HOME')}/.spook/notifier.moon"
    command = spook_config.command

  mapper = require("file_mapper")(file_mapping)
  if args.command and #args.command > 0
    log.debug "parsing command..."
    log.debug args.command
    log.debug #args.command
    command = args.command

  if args.notifier
    notifier_path = args.notifier

  if args.watch
    watch_dirs = args.watch

  status, notifier = pcall(-> return moonscript.loadfile(notifier_path)!)

  if not status
    log.debug "Couldn't load #{notifier_path}, loading default notifier"
    notifier = require "default_notifier"

  if watch_dirs
    watch_dirs = require("dir_list")(watch_dirs)
  else
    watch_dirs = require("stdin_list")()

  spook = require "spook"
  runner, watchers = spook mapper, notifier, command, watch_dirs, args
  runner\run!
