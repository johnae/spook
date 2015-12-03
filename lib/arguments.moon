argparse = require "argparse"
fs = require "fs"

parser = argparse name: "spook", description: "Watches for changes and runs functions (and commands) in response", epilog: "For more see https://github.com/johnae/spook"

parser\argument("command", "Expects the command to run which will be given as input the output of the mapping (in Spookfile), enclose it in quotes!")\args "0-1"

parser\flag("-v --version", "Show the Spook version you're running and exit")\action ->
  print(require "version")
  os.exit 0

parser\flag("-s --setup", "Setup Spook - creates #{os.getenv('HOME')}/.spook/notifiers and a default notifier (will overwrite #{os.getenv('HOME')}/.spook/notifiers/default/terminal_notifier.moon)")\action ->
  if fs.is_dir "#{os.getenv('HOME')}/.spook" and not fs.is_dir "#{os.getenv('HOME')}/.spook/notifiers/default"
    print "Don't forget to move any notifiers you had in '#{os.getenv('HOME')}/.spook'"
    print "to '#{os.getenv('HOME')}/.spook/notifiers or any subdir and update your Spookfile(s) to"
    print "point to '#{os.getenv('HOME')}/.spook/notifiers (all of them will load, from any subdirs)"

  fs.mkdir_p "#{os.getenv('HOME')}/.spook/notifiers/default"
  f = io.open "#{os.getenv('HOME')}/.spook/notifiers/default/terminal_notifier.moon", "wb"
  -- a simple replacement string
  -- will replace the contents with
  -- whatever is in lib/terminal_notifier.moon
  -- happens at compile time - see tools/pack.lua
  content = [[READ_FILE_terminal_notifier.moon]]
  f\write(content)
  f\close!
  os.exit 0

parser\flag("-i --initialize", "Initialize an example Spookfile in the current dir")\action ->
  f = io.open("Spookfile", "wb")
  content = [[
-- How much output do we want?
log_level "INFO"

-- Setup what directories to watch and what to do
-- when a file is changed. "command" is a helper
-- for setting up what command to run. There is no
-- restriction on running shell commands however -
-- any function (in lua/moonscript) can be run
watch "app", "lib", "spec", ->
  cmd = command "./bin/rspec -f d"
  on_changed "^(spec)/(spec_helper%.rb)", -> cmd "spec"
  on_changed "^spec/(.*)_spec%.rb", (a) -> cmd "spec/#{a}_spec.rb"
  on_changed "^lib/(.*)%.rb", (a) -> cmd "spec/lib/#{a}_spec.rb"
  on_changed "^app/(.*)%.rb", (a) -> cmd "spec/#{a}_spec.rb"

-- Perhaps some area where we experiment, sort of
-- like a poor mans REPL
watch "playground", ->
  cmd = command "ruby"
  on_changed "^playground/(.*)%.rb", (a) -> cmd "playground/#{a}.rb"

-- If a "command" isn't what you want to run, as mentioned, any function
-- can be run in response to a change. here's an example of how that might look:
-- handle_file = (file) ->
--   f = assert io.open(file, 'r')
--   content = f\read!
--   f\close!
--   new_content = "do stuff do content: #{content}"
--   o = assert io.open('/tmp/new_file.txt', 'w')
--   o\write new_content
--   o\close!
--   true -- return true or false for notications
-- do_stuff = (file) ->
--   notify.begin description: "do_stuff #{file}", detail: file, -> handle_file file -- for terminal etc notifications
-- watch "stuff", ->
--   on_changed "stuff/(.*)/(.*)%.txt", (a, b) -> do_stuff "stuff/#{a}/#{b}.txt"

-- Define notifiers to use, a default one (including directory structure) is created for you
-- when you run "spook --setup". All notifiers in specified dir are loaded and if their "runs"
-- function returns true they will be run (if there is no runs function they will also run).
-- Set log_level to DEBUG to see whether there's a failure in loading them. Either
-- through command line switch -l or in this file.
notifier "#{os.getenv('HOME')}/.spook/notifiers"

-- You can even specify a notifier right here (perhaps for simpler variants), like:
--notifier {
--  start: (info) ->
--    print "#{info.description} "#{info.detail}"
--  finish: (success, info) ->
--    if success
--      print "Success! in #{info.elapsed_time} s"
--    else
--      print "Failure! in #{info.elapsed_time} s"
--}

-- Commands can be defined at top level too if more convenient, like:
-- cmd1 = command "ls -lah"

-- Yes commands can be defined with a placeholder for the file which
-- can come in handy. You may use <file>, [file] or {file} one or more
-- times. It is replaced with the path to the file given to the command
-- when running it - in such cases it's no longer added as the last input
-- to the command.
-- cmd2 = command "cat [file] | gzip -c > [file].gz"

-- and can be used wherever below inside a watch/on_changed statement.
-- watch "some_place", ->
--   on_changed "^some_place/(.*)/(.*).txt", (a, b) -> cmd1 "stuff/#{a}/#{b}_thing.txt"
--   on_changed "^other_place/(.*)/(.*).txt", (a, b) -> cmd2 "other_stuff/#{a}/#{b}_thing.txt"
]]
  f\write(content)
  f\close!
  os.exit 0

parser\option("-l --log-level", "Log level either ERR, WARN, INFO or DEBUG")\args(1)

parser\option("-n --notifier", "Expects a path to a notifier moonscript file")\args(1)

parser\option("-c --config", "Expects the path to a Spook config file (eg. Spookfile) - overrides the default of loading a Spookfile from cwd")\args("1")

parser\option("-f --file", "Expects a path to a moonscript file - this runs the script within the context of spook, skipping the default behavior completely")\args(1)

parser
