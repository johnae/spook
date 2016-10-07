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

-- Require some things that come with spook
fs = require 'fs'
:note, :notifies = require('notifications')!
note.add 'terminal_notifier' -- this does a require since it's a string
-- a notifier could be added right here, like:
-- node.add {
--   start: (msg, info) ->
--     print "Start, yay"
--   success: (msg, info) ->
--     print "Success, yay!"
--   fail: (msg, info) ->
--     print "Fail, nay!"

-- Define a function for running rspec
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

-- Setup what directories to watch and what to do
-- when a file is changed. "command" is a helper
-- for setting up what command to run. There is no
-- restriction on running shell commands however -
-- any function (in lua/moonscript) can be run
watch 'app', 'lib', 'spec', ->
  on_changed '^(spec)/(spec_helper%.rb)', (event) ->
    notifies event.path, event, ->
      rspec 'spec'

  on_changed '^spec/(.*)_spec%.rb', (event, name) ->
    notifies event.path, event, ->
      rspec "spec/#{a}_spec.rb"

  on_changed '^lib/(.*)%.rb', (event, name) ->
    notifies event.path, event, ->
      rspec "spec/lib/#{a}_spec.rb"

  on_changed '^app/(.*)%.rb', (event, name) ->
    notifies event.path, event, ->
      rspec "spec/#{a}_spec.rb"

-- Just some experimentation perhaps?
-- Here we skip notifications.
watch 'playground', ->
  on_changed '^playground/(.*)%.rb', (event, name) ->
    ruby "playground/#{a}.rb"

-- Let's reload this file when changing it, therefore
-- spook itself can be reconfigured without restarting it.
watchnr '.', ->
  on_changed 'Spookfile', (event) ->
    note.info 'Reloading Spookfile...'
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
