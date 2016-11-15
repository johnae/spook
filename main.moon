-- load the core
require "vendor"
require "lib"
lpeg = require "lpeglj"
package.loaded.lpeg = lpeg
require "globals"
getcwd = getcwd

-- add some default load paths
package.path = package.path .. ";#{getcwd!}/.spook/lib/?.lua"
package.path = package.path .. ";#{getcwd!}/.spook/lib/?/init.lua"
package.path = package.path .. ";#{os.getenv('HOME')}/.spook/lib/?.lua"
package.path = package.path .. ";#{os.getenv('HOME')}/.spook/lib/?/init.lua"

-- setup additional requirements
require "moonscript"
_G.log = require'log'
moonscript = require "moonscript.base"
colors = require 'ansicolors'
{:index_of} = table
arg = arg
log = _G.log
log.level log.INFO

loadfail = (file, result) ->
  print colors "%{red}FATAL: Failed to load '#{file}'"
  print colors "%{white}#{result}" if result
  print ""
  print colors "%{dim}This may indicate a syntax error or that some logic failed"
  os.exit 1

-- if there is an argument "-f" on the commandline
-- we completely skip the default behavior and run
-- whatever script path given within the context of
-- spook. Quite similar to running the file with just
-- luajit path/to/some/file, with the obvious difference
-- that here it is run within the spook context and all
-- that comes built-in is available (including moonscript, so
-- moonscript files can be run as well as lua files).
if fi = index_of arg, "-f"
  file = arg[fi + 1]
  new_args = [a for i, a in ipairs arg when i>(fi + 1)]
  unless file
    log.error "The -f option requires an argument"
    os.exit 1
  _G.arg = new_args
  success, chunk = if file\match("[^.]%.lua$")
    loadfile(file)
  else
    moonscript.loadfile(file)
  loadfail file, chunk unless success
  return chunk!

cli = require "arguments"
run = require'event_loop'.run
Spook = require 'spook'
args = cli\parse!
spookfile_path = args.config or os.getenv('SPOOKFILE') or "Spookfile"
local spook, queue

-- to prevent multiple events happening very quickly
-- on a specific file we need to run a handler on some
-- interval which coalesces the events into one (here it's
-- just the latest event, disregarding any previous ones).
event_handler = =>
  seen_paths = {}
  while #queue > 0
    event = queue\popright! -- latest event
    if event.type == 'fs'
      continue unless event.path -- ignore events without a path
      continue if seen_paths[event.path] -- ignore events we've already seen
      seen_paths[event.path] = true
      matching = spook\match event
      if matching and #matching > 0
        for handler in *matching
          success, result = pcall handler
          unless success
            log.debug "An error occurred in change_handler: #{result}"
          break if spook.first_match_only -- the default
  @again!

-- this is finally setting up spook from the Spookfile
-- this function is also made available globally which
-- makes it possible to reload the Spookfile from the Spookfile
-- itself (probably based on some event like a change to the
-- Spookfile).
load_spookfile = ->
  spook\stop! if spook
  success, result = pcall moonscript.loadfile, spookfile_path
  loadfail spookfile_path, result unless success
  spookfile = result
  spook = Spook.new!
  if args.log_level
    spook.log_level = args.log_level if args.log_level
  _G.spook = spook
  queue = spook.queue
  success, result = pcall -> spook spookfile
  loadfail spookfile_path, result unless success
  -- this is the actual event_handler above, the
  -- 0.35 interval is something I've found works
  -- reasonably well (on Linux at least).
  spook\timer 0.35, event_handler
  dir_or_dirs = (num) ->
    num == 1 and 'directory' or 'directories'
  file_or_files = (num) ->
    num == 1 and 'file' or 'files'

  if log[spook.log_level] > log.WARN
    log.info colors "[ %{blue}Watching #{spook.num_dirs} #{dir_or_dirs(spook.num_dirs)} recursively %{reset}]"
    log.info colors "[ %{blue}Watching #{spook.file_watches} single #{file_or_files(spook.file_watches)} %{reset}]"

  spook\start!

_G.load_spookfile = load_spookfile
load_spookfile!
run!
