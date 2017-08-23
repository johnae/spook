-- load the core
require "vendor"
require "lib"
lpeg = require "lpeglj"
package.loaded.lpeg = lpeg
require "globals"
S = require 'syscall'
:execute, :children = require 'process'
:readline = require 'utils'
fs = require 'fs'
getcwd = getcwd
insert: append, :concat, remove: pop, :clear, :sort = table

-- add some default load paths
for base in *{getcwd!, os.getenv('HOME')}
  package.path = package.path ..
    ";#{base}/.spook/lib/?.lua" ..
    ";#{base}/.spook/lib/?/init.lua"

-- setup additional requirements
require "moonscript"
_G.log = require 'log'
_G.notify = require('notify')!
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
    pcall loadfile, file
  else
    pcall moonscript.loadfile, file
  loadfail file, chunk unless success
  return chunk!

cli = require "arguments"
:run, :signalreset, :epoll_fd = require 'event_loop'
Spook = require 'spook'
local spook, event_stack

fs_event_to_env = (event) ->
  S.setenv('SPOOK_CHANGE_PATH', event.path, true)
  S.setenv('SPOOK_CHANGE_ACTION', event.action, true)
  S.unsetenv('SPOOK_MOVED_FROM')
  if event.action == 'moved'
    S.setenv('SPOOK_MOVED_FROM', event.from, true)

-- to prevent multiple events happening very quickly
-- on a specific file we need to run a handler on some
-- interval which coalesces the events into one (here it's
-- just the latest event, disregarding any previous ones).
event_handler = =>
  seen_paths = {}
  local pevent
  while #event_stack > 0
    -- latest event that occurred (well, according to the OS anyway),
    -- because the last fs events are (usually) the more interesting
    -- ones in practice.
    event = pop event_stack
    continue unless event.path -- ignore events without a path
    continue if seen_paths[event.path] -- ignore events we've already seen
    fs_event_to_env event
    seen_paths[event.path] = true
    matching = spook\match event
    if matching and #matching > 0
      for handler in *matching
        success, result = pcall handler
        unless success
          log.debug "An error occurred in change_handler: #{result}"
        break if spook.first_match_only -- the default
  @again!

kill_children = ->
  killed = 0
  for pid, process in pairs children
    S.kill -pid, "KILL"
    S.waitpid pid
    children[pid] == nil
    killed += 1
  dead_children = (num) -> num == 1 and "#{num} child" or "#{num} children"
  if killed > 0
    io.stderr\write colors "[ %{red}#{dead_children(killed)} killed%{reset} ]\n"

signaled_at = 0
start = ->
  print = print
  tostring = tostring
  os = os
  io = io
  for sig in *{'int', 'term', 'quit'}
    spook\on_signal sig, (s) ->
      killall = gettimeofday! - signaled_at < 500
      signaled_at = gettimeofday!
      unless killall
        killed = 0
        for pid, process in pairs children
          S.kill -pid, "term"
          killed += 1
        dead_children = (num) -> num == 1 and "#{num} child" or "#{num} children"
        if killed > 0
          io.stderr\write colors "[ %{red}#{dead_children(killed)} terminated%{reset} ]\n"
          return if S.stdin\isatty!
      kill_children!
      s\stop!
      spook\stop!
      io.stderr\write colors "Killed by SIG#{sig\upper!}.\n"
      os.exit(1)

  -- 0.35 interval is something I've found works
  -- reasonably well.
  spook\after 0.35, event_handler
  spook\start!

-- this is finally setting up spook from the Spookfile
-- this function is also made available globally which
-- makes it possible to reload the Spookfile from the Spookfile
-- itself (probably based on some event like a change to the
-- Spookfile).
load_spookfile = ->
  args = cli\parse!
  spookfile_path = args.config or os.getenv('SPOOKFILE') or "Spookfile"
  spook\stop! if spook
  success, result = pcall moonscript.loadfile, spookfile_path
  loadfail spookfile_path, result unless success
  spookfile = result
  spook = Spook.new!
  if args.log_level
    spook.log_level = args.log_level if args.log_level
  _G.spook = spook
  _G.notify.clear!
  event_stack = spook.event_stack
  success, result = pcall -> spook spookfile
  loadfail spookfile_path, result unless success
  dir_or_dirs = (num) ->
    num == 1 and 'directory' or 'directories'
  file_or_files = (num) ->
    num == 1 and 'file' or 'files'

  if log[spook.log_level] > log.WARN
    notify.info colors "%{blue}Watching #{spook.num_dirs} #{dir_or_dirs(spook.num_dirs)}%{reset}"
    notify.info colors "%{blue}Watching #{spook.file_watches} single #{file_or_files(spook.file_watches)}%{reset}"

  start!

_G.load_spookfile = load_spookfile

-- this reexecutes spook which means doing a full reload
_G.reload_spook = ->
  signalreset!
  epoll_fd\close! if epoll_fd
  args = {"/bin/sh", "-c", _G.arg[0]}
  append args, arg for arg in *_G.arg
  cmd = args[1]
  S.execve cmd, args, ["#{k}=#{v}" for k, v in pairs S.environ!]

stdin_input = ->
  sel = S.select(readfds: {S.stdin}, 0.01)
  return if sel.count == 0
  -- using a table because excessive string concatenation
  -- in Lua is the wrong approach and will be very slow here
  input = {}
  append input, line for line in readline(S.stdin)
  return unless #input > 0
  input

expand_file = (data, file) ->
  return nil unless data
  filename, ext = fs.name_ext file
  basename = fs.basename file
  basenamenoext = fs.basename filename
  data = data\gsub '([[{%<](file)[]}>])', file
  data = data\gsub '([[{%<](filenoext)[]}>])', filename
  data = data\gsub '([[{%<](basename)[]}>])', basename
  data\gsub '([[{%<](basenamenoext)[]}>])', basenamenoext

-- This may seem a bit convoluted, perhaps it is. However finding
-- the common top directories among several hundred thousand paths
-- isn't entirely trivial.
-- This basically finds the top directories to watch
-- in a list of files (eg. perhaps from ls or find . -type f)
-- for example, this file list:
-- ./a/b/c/d/e/file-e.txt
-- ./a/b/c/file-c.txt
-- ./b/c/file-bc.txt
-- ./b/c/e/file-bc.txt
-- should give us this list of dirs (to watch):
-- ./a/b/c
-- ./b/c
watch_dirs = (files) ->
  dirs = {}
  -- normalize the paths, eg. a/b/c/file.txt becomes ./a/b/c
  for path in *files
    path_start = path\sub 1, 1
    path = path\split '/'
    unless (path_start == '/' or path_start == '.')
      p = path
      path = {'.'}
      for seg in *p
        append path, seg

    local prev_node, prev_seg
    cur_node = dirs
    for idx, seg in ipairs path
      -- break if a zero was ever written to this node
      break if cur_node[seg] == 0
      if idx == #path
        if prev_seg
          prev_node[prev_seg] = 0 -- overwrite anything at this node with a 0
        break

      cur_node[seg] or= {}
      prev_seg = seg
      prev_node = cur_node
      cur_node = cur_node[seg]

  -- finally return a generator
  list = (tbl, path) ->
    for k, v in pairs tbl
      p = path and "#{path}/#{k}" or k
      if v == 0
        coroutine.yield p
      else
        list v, p

  coroutine.wrap -> list dirs

-- if there's anything on stdin, then work somewhat like entr: http://entrproject.org
watch_files_from_stdin = (files) ->
  spook\stop! if spook
  spook = Spook.new!
  _G.spook = spook
  _G.notify.clear!
  event_stack = spook.event_stack
  args = [a for i, a in ipairs arg when i > 0]
  start_now = false
  exit_after_exec = false
  if index_of(args, "-s") and index_of(args, "-o")
    print "-o can't be used with -s"
    os.exit 1

  if fi = index_of args, "-s"
    start_now = true
    args = [a for i, a in ipairs args when i > fi]

  if fi = index_of args, "-o"
    exit_after_exec = true
    args = [a for i, a in ipairs args when i > fi]

  command = if #args > 0
    concat ([a for i, a in ipairs args]), ' '
  filemap = {file\gsub('^%./',''), true for file in *files}

  pid = 0
  if start_now and command
    pid = coroutine.wrap(-> execute command)!

  is_match = (name) -> filemap[name]

  handler = if command
    (event, f) ->
      return unless is_match f
      clear event_stack -- empty the stack in place when we have a match
      cmdline = expand_file command, f
      if pid > 0
        S.kill -pid, "term"
      opts = {}
      if exit_after_exec
        opts.on_death = (success, exittype, exitstatus, pid) ->
          os.exit(0) if success
          os.exit(exitstatus) if exitstatus > 0
          os.exit(1)
      pid = coroutine.wrap(-> execute cmdline, opts)!
  else
    (event, f) ->
      return unless is_match f
      io.stderr\write colors "%{green}'#{f}'%{reset} changed, no command was given so I'm just echoing\n"

  for dir in watch_dirs(files)
    spook\watch dir, ->
      on_changed '(.*)', handler

  start!

if input = stdin_input!
  watch_files_from_stdin input
else
  load_spookfile!

run!
