argparse = require "argparse"

parser = argparse name: "spook", description: "Watches for changes and runs functions (and commands) in response", epilog: "For more see https://github.com/johnae/spook"

parser\argument("command", "Expects the command to run which will be given as input the output of the mapping (in Spookfile), enclose it in quotes!")\args "0-1"

parser\flag("-v --version", "Show the Spook version you're running and exit")\action ->
  print(require "version")
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
  on_changed "^spec/(.*)%_spec.rb", (a) -> cmd "spec/#{a}_spec.rb"
  on_changed "^lib/(.*)%.rb", (a) -> cmd "spec/lib/#{a}_spec.rb"
  on_changed "^app/(.*)%.rb", (a) -> cmd "spec/#{a}_spec.rb"

-- For business and pleasure yeah?
watch "playground", ->
  cmd = command "ruby"
  on_changed "^playground/(.*)%.rb", (a) -> cmd "playground/#{a}.rb"

-- The notifier to use, skipped if it doesn't exist
-- turn on debug (-l DEBUG or in this file - see log_level above)
-- to see if it failed to load because there was no file or
-- some error parsing it
notifier "#{os.getenv('HOME')}/.spook/notifier.moon"

-- or you could specify the notifier here (for simpler variants), like
--notifier {
--  start: (changed_file, mapped_file) ->
--    print "#{changed_file} -> "#{mapped_file}"
--  finish: (status, changed_file, mapped_file) ->
--    if status
--      print "Success!"
--    else
--      print "Failure!"
--}
]]
  content = f\write(content)
  f\close()
  os.exit 0

parser\option("-l --log-level", "Log level either ERR, WARN, INFO or DEBUG")\args(1)

parser\option("-n --notifier", "Expects a path to a notifier moonscript file")\args(1)

parser\option("-c --config", "Expects the path to a Spook config file (eg. Spookfile) - overrides the default of loading a Spookfile from cwd")\args("1")

parser\option("-f --file", "Expects a path to a moonscript file - this runs the script within the context of spook, skipping the default behavior completely")\args(1)

parser
