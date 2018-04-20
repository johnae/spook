S = require "syscall"
C = S.c
:Read, :Signal, :epoll_fd, :signalreset = require 'event_loop'
:read = require 'utils'

-- kqueue isn't inherited by children
prepare_child = ->
  signalreset!
  if epoll_fd
    epoll_fd\close!

create_pipe = ->
  _, err, p_read, p_write = S.pipe!
  error err if err
  p_read, p_write

stdio_pipes = ->
  in_read, in_write = create_pipe!
  out_read, out_write = create_pipe!
  err_read, err_write = create_pipe!
  in_read, in_write, out_read, out_write, err_read, err_write

close_all = (...) -> stream\close! for stream in *{...}

process_env = (opts={}) ->
  env = {k, v for k, v in pairs S.environ!}
  if opts.env
    env[k] = v for k, v in pairs opts.env
  ["#{k}=#{v}" for k, v in pairs env]

children = {}
sigchld = Signal.new 'CHLD', (s) ->
  for pid, process in pairs children
    wpid, err, status = S.waitpid pid, C.W.NOHANG
    continue if wpid == 0
    continue if err and not err.CHILD
    children[pid] = nil
    success = false
    :thread, :on_death, :finish = process
    -- call finish if present, it will, atm only do final reads on the pipes then close them
    finish! if finish
    -- to be compatible with Luas os.execute we need these values
    exitstatus, exittype = if status
      if status.WTERMSIG
        status.WTERMSIG, "signal"
      else if status.WSTOPSIG
        status.WSTOPSIG, "signal"
      else if status.EXITSTATUS
        success = status.EXITSTATUS == 0
        status.EXITSTATUS, "exit"
    else
      -1, "exit"

    coroutine.resume thread, success, exittype, exitstatus, pid
    on_death(success, exittype, exitstatus, pid) if type(on_death) == 'function'

sigchld\start!

-- used like:
-- status = exec "ls -lah"
exec = (cmdline, opts={}) ->
  args = {"/bin/sh", "-c", "exec #{cmdline}"}
  env = process_env(opts)
  cmd = args[1]
  thread, main = coroutine.running!
  assert not main, "Error can't suspend main thread"
  process = {on_death: opts.on_death, :thread}

  child = ->
    prepare_child!
    S.execve cmd, args, env
    error "Oops - exec error, perhaps given program '#{cmd}' can't be found?"

  pid = S.fork!
  if pid == 0
    S.setpgid 0, S.getpid!
    child!
  else if pid > 0
    children[pid] = process
    coroutine.yield pid
  else
    error "fork error"

-- used like:
-- _, _, status = execute "ls -lah"
-- this is mainly for compat with Lua:s
-- built-in os.execute
execute = (cmdline, opts={}) ->
  success, exittype, exitstatus = exec cmdline, opts
  success, exittype, exitstatus

-- used like:
-- out = ""
-- status = spawn "ls -lah", on_err: some_handler, on_read: (data) -> out ..= data
spawn = (cmdline, opts={}) ->
  args = {"/bin/sh", "-c", cmdline}
  env = process_env(opts)
  cmd = args[1]
  thread, main = coroutine.running!
  assert not main, "Error can't suspend main thread"
  process = {on_death: opts.on_death, :thread}
  in_read, in_write, out_read, out_write, err_read, err_write = stdio_pipes!

  child = ->
    prepare_child!
    in_read\dup2 0
    out_write\dup2 1
    err_write\dup2 2
    close_all in_read, in_write, out_read, out_write, err_read, err_write
    S.execve cmd, args, env
    error "Oops - exec error, perhaps given program '#{cmd}' can't be found?"

  parent = (child_pid) ->
    local out_reader, err_reader
    close_all in_read, in_write, out_write, err_write
    out_read\nonblock!
    err_read\nonblock!
    on_read = opts.on_read or ->
    on_err = opts.on_err or ->

    out_reader = Read.new out_read, (r, fd) ->
      for bytes, err in read(fd)
        return if err and err.again
        error err if err
        on_read bytes

    err_reader = Read.new err_read, (r, fd) ->
      for bytes, err in read(fd)
        return if err and err.again
        error err if err
        on_err bytes

    -- as the we might get SIGCHLD we've read the full output
    -- we need a way to read any data left in the pipes. This
    -- is propagated to the SIGCHLD handler which will call finish
    -- if defined.
    process.finish = ->
      out_reader!
      out_reader\stop!
      err_reader!
      err_reader\stop!
      out_read\close!
      err_read\close!

    children[child_pid] = process

    out_reader\start!
    err_reader\start!

  pid = S.fork!
  if pid == 0
    S.setpgid 0, S.getpid!
    child!
  else if pid > 0
    parent pid
    coroutine.yield pid
  else
    error "fork error"

:exec, :spawn, :execute, :children
