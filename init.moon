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
lfs = require 'syscall.lfs'
getcwd = getcwd
gettimeofday = gettimeofday
insert: append, :concat, remove: pop, :clear = table
:max = math

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

if pi = index_of arg, "-p"
  pidfile = arg[pi + 1]
  if not pidfile or pidfile\match('^-')
    log.error "The -p option requires an argument"
    os.exit 1
  p = io.open(pidfile, "w")
  unless p
    log.error "Couldn't open given pidfile '#{pidfile}'"
    os.exit 1
  p\write S.getpid!

cli = require "arguments"
:run, :signalreset, :epoll_fd = require 'event_loop'
Spook = require 'spook'
local spook, fs_events

reset_env_fs_events = ->
  S.unsetenv(ev) for ev in *{
    'SPOOK_CHANGE_PATH',
    'SPOOK_CHANGE_ACTION',
    'SPOOK_MOVED_FROM'
  }

fs_event_to_env = (event) ->
  return unless event

  if event.path
    S.setenv('SPOOK_CHANGE_PATH', event.path, true)
  else
    log.debug "expected the event to have a path: ", event

  if event.action
    S.setenv('SPOOK_CHANGE_ACTION', event.action, true)
  else
    log.debug "expected the event to have an action: ", event

  if event.action == 'moved'
    if event.from
      S.setenv('SPOOK_MOVED_FROM', event.from, true)
    else
      log.debug "expected the event to have a from field: ", event

-- to prevent multiple events happening very quickly
-- on a specific file we need to run a handler on some
-- interval which coalesces the events into one (here it's
-- just the latest event, disregarding any previous ones).
event_handler = =>
  seen_paths = {}
  reset_env_fs_events!
  while #fs_events > 0
    event = pop fs_events
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
  for pid in pairs children
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
        for pid in pairs children
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
  -- reasonably well. So we collect events every interval.
  spook\after 0.35, event_handler
  spook\start!

-- this is finally setting up spook from the Spookfile
-- this function is also made available globally which
-- makes it possible to reload the Spookfile from the Spookfile
-- itself (probably based on some event like a change to the
-- Spookfile).
load_spookfile = ->
  args = cli\parse!
  spookfile_path = args.c or os.getenv('SPOOKFILE') or "Spookfile"
  spook\stop! if spook
  success, result = pcall moonscript.loadfile, spookfile_path
  loadfail spookfile_path, result unless success
  spookfile = result
  spook = Spook.new!
  if args.l
    spook.log_level = args.l\upper!
  _G.spook = spook
  _G.notify.clear!
  fs_events = spook.fs_events
  success, result = pcall -> spook spookfile
  loadfail spookfile_path, result unless success
  dir_or_dirs = (num) ->
    num == 1 and 'directory' or 'directories'
  file_or_files = (num) ->
    num == 1 and 'file' or 'files'

  if log[spook.log_level] > log.WARN
    _G.notify.info colors "%{blue}Watching #{spook.num_dirs} #{dir_or_dirs(spook.num_dirs)}%{reset}"
    _G.notify.info colors "%{blue}Watching #{spook.file_watches} single #{file_or_files(spook.file_watches)}%{reset}"

  start!

_G.load_spookfile = load_spookfile

-- this reexecutes spook which means doing a full reload of everything as
-- the old process is replaced by a new one.
_G.reload_spook = ->
  signalreset!
  epoll_fd\close! if epoll_fd
  args = {"/bin/sh", "-c", _G.arg[0]}
  append args, anarg for anarg in *_G.arg
  cmd = args[1]
  S.execve cmd, args, ["#{k}=#{v}" for k, v in pairs S.environ!]

stdin_input = ->
  -- if we have a controlling terminal, this doesn't apply
  return if S.isatty(S.stdin)
  -- wait for a specified time for input on stdin
  wait = 2.0
  take = take_while (item) -> item != '--'
  args = [a for a in *arg when take a]
  if w = index_of args, "-r"
    success, w = pcall tonumber, arg[w + 1]
    wait = w if success
  return if wait <= 0.0
  sel = S.select(readfds: {S.stdin}, wait)
  -- if there was no input, bail into normal spook mode
  if sel.count == 0
    print "Waited for data on stdin for #{wait}s but got nothing."
    return
  -- using a table because excessive string concatenation
  -- in Lua is the wrong approach and will be very slow here
  log.output io.stderr -- use stderr in stdin mode for logging
  input = {}
  append input, line for line in readline(S.stdin)
  return unless #input > 0
  input

expand_file = (data, file) ->
  return nil unless data
  filename, _ = fs.name_ext file
  basename = fs.basename file
  basenamenoext = fs.basename filename
  data = data\gsub '([[{%<](file)[]}>])', file
  data = data\gsub '([[{%<](filenoext)[]}>])', filename
  data = data\gsub '([[{%<](basename)[]}>])', basename
  data\gsub '([[{%<](basenamenoext)[]}>])', basenamenoext

-- for example, this file list:
-- ./a/b/c/d/e/file-e.txt
-- ./a/b/c/file-c.txt
-- ./b/c/file-bc.txt
-- ./b/c/e/file-bc.txt
-- should give us this list of dirs (to watch):
-- ./a/b/c/d/e
-- ./a/b/c
-- ./b/c
-- ./b/c/e
watch_dirs = (files) ->
  to_dir = (file) ->
    fst = file\sub 1, 1
    snd = file\sub 2, 2
    file = './' .. file if fst != '/' and "#{fst}#{snd}" != './'
    attr = lfs.attributes file
    unless attr
      if S.lstat file -- broken symbolic link - we can skip those I hope
        log.debug "Broken symbolic link here: '#{file}' - skipping"
        return nil
      log.error "What is this '#{file}' you give me? There's nothing called that where you say there is.\nDid you use your special awesome 'ls' alias that outputs very cool stuff maybe?\nPlease give me actual names of files or directories. The standard find utility usually does a good job.\n\nAnyway - k thx bye."
      os.exit 1
    attr.mode == 'directory' and file or fs.dirname(file)
  dirs = [to_dir(file) for file in *files when to_dir(file)]
  dirmap = {lfs.attributes(dir).ino, dir for dir in *dirs}
  [dir for _, dir in pairs dirmap]

-- if there's anything on stdin, then work somewhat like entr: http://entrproject.org
watch_files_from_stdin = (files) ->
  io.stdout\setvbuf 'no'
  spook\stop! if spook
  spook = Spook.new!
  _G.spook = spook
  _G.notify.clear!
  fs_events = spook.fs_events
  start_now = false
  exit_after_event = false
  take = take_while (item) -> item != '--'
  args = [a for a in *arg when take(a)]

  local si, oi, ll, pp
  if si = index_of args, "-s"
    start_now = true
  si or= 0

  if oi = index_of args, "-o"
    exit_after_event = true
  oi or= 0

  if ll = index_of args, "-l"
    ll += 1
    spook.log_level = arg[ll]\upper!
  ll or= 0

  if pp = index_of args, "-p"
    pp += 1
  pp or= 0

  li = max(max(max(si, oi), ll), pp)
  take = drop_while (index, item) -> index <= li or item == '--'
  args = [a for i, a in ipairs arg when take i, a]

  command = if #args > 0
    concat ([a for i, a in ipairs args]), ' '
  filemap = {file\gsub('^%./',''), true for file in *files}

  pid = 0
  if start_now and command
    pid = coroutine.wrap(-> execute command)!

  is_match = (name) -> filemap[name]

  handler = if command
    (event, f) ->
      if exit_after_event and pid > 0
        S.kill -pid, "term"
        os.exit(0)

      return unless is_match f

      S.kill -pid, "term" if start_now

      clear fs_events -- empty the event list in place when we have a match
      cmdline = expand_file command, f
      opts = {}
      if exit_after_event
        opts.on_death = (success, exittype, exitstatus) ->
          os.exit(0) if success
          os.exit(exitstatus) if exitstatus > 0
          os.exit(1)
      pid = coroutine.wrap(-> execute cmdline, opts)!
  else
    (event, f) ->
      unless is_match f
        os.exit(0) if exit_after_event
        return
      io.stdout\write f, "\n"
      os.exit(0) if exit_after_event

  dirs = watch_dirs(files)
  log.debug "Start watching #{#dirs} (unique) directories..."
  log.debug "Matching events against #{#files} files..."
  spook\watchnr dirs, ->
    on_changed '(.*)', handler

  start!

t = timer "initialization"
if input = stdin_input!
  watch_files_from_stdin input
else
  load_spookfile!
t log.debug
run!