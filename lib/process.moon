-- These are meant to be used with a coroutine based evented application. Eg.
-- for writing serial looking code that isn't, or in other words: avoiding
-- callback soup. Using spook for running tests, for example - this may not be
-- very useful.

S = require "syscall"
C = S.c
:Read, :Signal, :epoll_fd, :signalunblock = require 'event_loop'

-- kqueue isn't inherited by children
prepare_child = ->
  signalunblock 'CHLD'
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

read = (fd, count = 4096) -> ->
  bytes, err = fd\read nil, count
  return "", err if err
  return nil if #bytes == 0
  bytes

process_env = (opts={}) ->
  env = {k, v for k, v in pairs S.environ!}
  if opts.env
    env[k] = v for k, v in pairs opts.env
  ["#{k}=#{v}" for k, v in pairs env]

commands = {}
sigchld = Signal.new 'CHLD', (s) ->
  for pid, thread in pairs commands
    _, err, status = S.waitpid pid, C.W.NOHANG
    continue if err
    commands[pid] = nil
    coroutine.resume thread, status.EXITSTATUS
sigchld\start!

-- used like:
-- status = exec "ls -lah"
exec = (cmdline, opts={}) ->
  args = {"/bin/sh", "-c", cmdline}
  env = process_env(opts)
  cmd = args[1]
  thread, main = coroutine.running!
  assert not main, "Error can't suspend main thread"

  child = ->
    prepare_child!
    S.execve cmd, args, env
    error "Oops - exec error, perhaps given program '#{cmd}' can't be found?"

  pid = S.fork!
  if pid == 0
    child!
  else if pid > 0
    commands[pid] = thread
    coroutine.yield!
  else
    error "fork error"

-- used like:
-- _, _, status = execute "ls -lah"
-- this is mainly for (sort of) compat
-- with Lua:s built-in os.execute which
-- returns success, type_of_exit, status
execute = (cmdline, opts={}) ->
  status = exec cmdline, opts
  true, "exit", status

-- used like:
-- out = ""
-- status = spawn "ls -lah", on_err: some_handler, on_read: (data) -> out ..= data
spawn = (cmdline, opts={}) ->
  args = {"/bin/sh", "-c", cmdline}
  env = process_env(opts)
  cmd = args[1]
  thread, main = coroutine.running!
  assert not main, "Error can't suspend main thread"
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
    resuming = false

    resume = ->
      return if resuming
      return unless (out_reader.stopped and err_reader.stopped)
      resuming = true
      _, _, status = S.waitpid child_pid
      coroutine.resume thread, status.EXITSTATUS

    out_reader = Read.new out_read, (r, fd) ->
      for bytes, err in read(fd)
        return if err and err.again
        error err if err
        on_read bytes
      r\stop!
      out_read\close!
      resume!

    err_reader = Read.new err_read, (r, fd) ->
      for bytes, err in read(fd)
        return if err and err.again
        error err if err
        on_err bytes
      r\stop!
      err_read\close!
      resume!

    out_reader\start!
    err_reader\start!

  pid = S.fork!
  if pid == 0
    child!
  else if pid > 0
    parent pid
    coroutine.yield!
  else
    error "fork error"

:exec, :spawn, :execute, :read
