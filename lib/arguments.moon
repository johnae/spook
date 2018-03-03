argparse = require "argparse"
fs = require "fs"
chdir = _G.chdir

parser = argparse name: "spook", description: "Watches for changes and runs functions (and commands) in response, based on a config file (eg. Spookfile) or watches any files it is given on stdin (similar to the entrproject).", epilog: "For more see https://github.com/johnae/spook"

parser\flag("-v --version", "Show the Spook version you're running and exit")\action ->
  print(require "version")
  os.exit 0

parser\flag("-i --initialize", "Initialize an example Spookfile in the current dir")\action ->
  f = io.open("Spookfile", "wb")
  content = [[
-- vim: syntax=moon
-- How much log output can you handle? (ERR, WARN, INFO, DEBUG)
log_level "INFO"

-- Require some things that come with spook
fs = require 'fs'

-- We want to use the coroutine based execute which can also be
-- interrupted using ctrl-c etc. I would recommend this most of the
-- time even though os.execute works just fine (except for job control etc).
execute = require('process').execute

-- Adds the built-in terminal_notifier
notify.add 'terminal_notifier'

-- if the added notifier is a string it will be loaded using
-- 'require'. It can also be specified right here, like:
-- notify.add {
--   start: (msg, info) ->
--     print "Start, yay"
--   success: (msg, info) ->
--     print "Success, yay!"
--   fail: (msg, info) ->
--     print "Fail, nay!"
-- }

-- If we find 'notifier' in the path, let's
-- add that notifier also but fail silently
-- if something goes wrong (eg. wasn't
-- found in path or a syntax error).
pcall notify.add, 'notifier'

-- Define a function for running rspec.
-- Please see https://github.com/johnae/spook
-- for more advanced examples which you may
-- be interested in if you want to replace
-- ruby guard.
rspec = (file) ->
  return true unless fs.is_file file
  notify.info "RUNNING rspec #{file}"
  _, _, status = execute "./bin/rspec -f d #{file}"
  assert status == 0, "rspec #{file} - failed"

-- And another for running ruby files
ruby = (file) ->
  return true unless fs.is_file file
  notify.info "RUNNING ruby #{file}"
  _, _, status = execute "ruby #{file}"
  assert status == 0, "ruby #{file} - failed"
  status == 0

-- For more advanced use of notifications, reruns, task filtering
-- etc. Please see "spookfile_helpers". There should be good examples
-- of usage in spook's own Spookfile.

-- Setup what directories to watch and what to do
-- when a file is changed. For notifications, the
-- function(s) to run should be wrapped in a "notifies"
-- call and possibly other calls from spookfile_helpers.
-- See spook's own Spookfile for examples of that or
-- browse the README at https://github.com/johnae/spook.
watch '.', ->
  on_changed '^(spec)/(spec_helper%.rb)', (event) ->
    rspec 'spec'

  on_changed '^spec/(.*)_spec%.rb', (event, name) ->
    rspec "spec/#{a}_spec.rb"

  on_changed '^lib/(.*)%.rb', (event, name) ->
    rspec "spec/lib/#{a}_spec.rb"

  on_changed '^app/(.*)%.rb', (event, name) ->
    rspec "spec/#{a}_spec.rb"

  -- Some experimentation perhaps?
  on_changed '^playground/(.*)%.rb', (event, name) ->
    ruby "playground/#{a}.rb"

  -- have spook re-execute itself when the Spookfile changes,
  -- a "softer" version would be load_spookfile! but normally
  -- it's simpler and cleaner to just re-execute.
  on_changed '^Spookfile$', ->
    notify.info 'Re-executing spook...'
    reload_spook!

-- There are also single file watches. These MAY be useful if
-- you're doing something very specific rather than watching a
-- directory structure.
-- watch_file 'Spookfile', ->
--   on_changed (event) ->
--     notify.info 'Re-executing spook...'
--     reload_spook!

]]
  f\write(content)
  f\close!
  os.exit 0

parser\option("-l --log-level", "Log level either ERR, WARN, INFO or DEBUG")\args(1)

parser\option("-c --config", "Expects the path to a Spook config file (eg. Spookfile) - overrides the default of loading a Spookfile from cwd")\args("1")

parser\option("-w --dir", "Expects the path to working directory - overrides the default of using wherever spook was launched")\args("1")\action (args, _, dir) ->
  if fs.is_dir dir
    chdir dir
  else
    print "#{dir} is not a directory"
    os.exit 1

parser\option("-f file", "Expects a path to a MoonScript or Lua file - runs the script within the context of spook, skipping the default behavior completely. Any arguments following the path to the file will be given to the file itself.")\args(1)

parser\flag("-s", "In entr mode, start the given utility immediately without waiting for changes first - can't be used with -o. The utility to run should be given as the last arg(s) on the commandline. Without a utility spook will output the changed file path.")

parser\flag("-o", "In entr mode, exit immediately after running utility - can't be used with -s. The utility to run should be given as the last arg(s) on the commandline. Without a utility spook will output the changed file path.")

parser\flag("-r", "Wait this many seconds for data on stdin before bailing (default 2 seconds, 0 ofc means don't wait for any data at all)")\args(1)

parser
