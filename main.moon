require "vendor"
require "lib"
lpeg = require "lpeglj"
package.loaded.lpeg = lpeg
require "moonscript"
require "globals"
config = require("config")!
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

  _G.log = conf.log

  spook = require "spook"
  runner, watchers = spook conf
  runner\run!
