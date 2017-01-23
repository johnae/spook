argparse = require "argparse"
fs = require "fs"
chdir = _G.chdir

parser = argparse name: "spook", description: "Watches for changes and runs functions (and commands) in response, based on a config file (eg. Spookfile)", epilog: "For more see https://github.com/johnae/spook"

parser\flag("-v --version", "Show the Spook version you're running and exit")\action ->
  print(require "version")
  os.exit 0

parser\flag("-i --initialize", "Initialize an example Spookfile in the current dir")\action ->
  f = io.open("Spookfile", "wb")
  content = [[
-- vim: syntax=moon
-- How much log output can you handle? (ERR, WARN, INFO, DEBUG)
log_level "INFO"

-- Make it a local for use in handlers. In Lua
-- it's generally preferable to make locals.
load_spookfile = _G.load_spookfile

-- Require some things that come with spook
fs = require 'fs'

-- notify is a global variable. Let's make it a local
-- as is generally recommended in Lua.
-- Let's add the built-in terminal_notifier.
notify = _G.notify

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
-- if something goes wrong (eg. not there).
pcall notify.add, 'notifier'

-- Define a function for running rspec.
-- Please see https://github.com/johnae/spook
-- for more advanced examples which you may
-- be interested in if you want to replace
-- guard.
rspec = (file) ->
  return true unless fs.is_file file
  note.info "RUNNING rspec #{file}"
  _, _, status = os.execute "./bin/rspec -f d #{file}"
  assert status == 0, "rspec #{file} - failed"

-- And another for running ruby
ruby = (file) ->
  return true unless fs.is_file file
  note.info "RUNNING ruby #{file}"
  _, _, status = os.execute "ruby #{file}"
  assert status == 0, "ruby #{file} - failed"
  status == 0

-- For more advanced use of notifications, reruns, task filtering
-- etc. Please see "spookfile_helpers". There should be good examples
-- of usage in spook's own Spookfile.

-- Setup what directories to watch and what to do
-- when a file is changed. For notifications, the
-- function(s) to run should be wrapped in a "notifies"
-- call as below. The first argument to notifies is
-- the name of the event. Some notifiers may use this
-- for reporting. The second argument are the options,
-- those can be any table really. Certain keys in that
-- that table will be set by the notification system - such
-- as a timestamp for every notification run (which can
-- be used later to calculate how long a task took).
watch 'app', 'lib', 'spec', ->
  on_changed '^(spec)/(spec_helper%.rb)', (event) ->
    rspec 'spec'

  on_changed '^spec/(.*)_spec%.rb', (event, name) ->
    rspec "spec/#{a}_spec.rb"

  on_changed '^lib/(.*)%.rb', (event, name) ->
    rspec "spec/lib/#{a}_spec.rb"

  on_changed '^app/(.*)%.rb', (event, name) ->
    rspec "spec/#{a}_spec.rb"

-- Just some experimentation perhaps?
-- Here we don't bother with notifications.
watch 'playground', ->
  on_changed '^playground/(.*)%.rb', (event, name) ->
    ruby "playground/#{a}.rb"

-- Let's reload this file when changing it, therefore
-- spook itself can be reconfigured without restarting it.
watch_file 'Spookfile', ->
  on_changed (event) ->
    notify.info 'Reloading Spookfile...'
    load_spookfile!

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

parser\option("-f --file", "Expects a path to a moonscript file - this runs the script within the context of spook, skipping the default behavior completely")\args(1)

parser
