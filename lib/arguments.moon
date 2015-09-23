argparse = require "argparse"

parser = argparse name: "spook", description: "Watches for changes and runs commands in response", epilog: "For more see https://github.com/johnae/spook"

parser\argument("command", "Expects the command to run which will be given as input the output of the mapping (in Spookfile), enclose it in quotes!")\args "0-1"

parser\flag("-v --version", "Show the Spook version you're running and exit")\action ->
  print(require "version")
  os.exit 0

parser\flag("-i --initialize", "Initialize an example Spookfile in the current dir")\action ->
  f = io.open("Spookfile", "wb")
  content = [[
-- How much output do we want?
log_level "INFO"

-- Directories to watch for changes
watch {"app","lib","spec"}

-- How (changed) files are mapped to tests which become the input to the command to run
-- below is for a Rails app. If order must be preserved. Make this a list of k,v tables.
-- They will be evaluated first to last in that case.
map {
  {"^(spec)/(spec_helper%.rb)": (a,b) -> "spec"}
  {"^spec/(.*)%.rb": (a,b) -> "spec/#{a}.rb"}
  {"^lib/(.*)%.rb": (a,b) -> "spec/lib/#{a}_spec.rb"}
  {"^app/(.*)%.rb": (a,b) -> "spec/#{a}_spec.rb"}
}
-- You can return more than one value from a matcher, the second value should
-- in that case be the command you want to run for that specific match overriding
-- the default command - the mapped file is given as argument to the command, example:
--map {
--  {"^assets/(.*)%.coffee": (a,b) -> "assets/#{a}.coffee", "/usr/local/brew_coffee -o assets/#{a}.js"}
--  {"^lib/(.*)%.rb": (a,b) -> "spec/lib/#{a}_spec.rb"}
--  {"^app/(.*)%.rb": (a,b) -> "spec/#{a}_spec.rb"}
--}

-- The command to run on changes (the mapped file will be it's argument)
-- below is for a Rails/ruby app tested with rspec
command "./bin/rspec -f d"

-- The notifier to use, skipped if it doesn't exist
-- turn on debug (-l DEBUG or in this file - see log_level)
-- to see if it failed to load because there was no file or
-- some error parsing it
notifier "#{os.getenv('HOME')}/.spook/notifier.moon"

-- or you could specify the notifier here (for simpler variants), like
--notifier {
--  start: (changed_file, mapped_file) ->
--    print "#{changed_file} -> "#{mapped_file}"
--  finish: (status, changed_file, mapped_file) ->
--    if status == 0
--      print "Success!"
--    else
--      print "Failure!"
--}

-- Show what's being run (or not)
show_command true
]]
  content = f\write(content)
  f\close()
  os.exit 0

parser\option("-l --log-level", "Log level either ERR, WARN, INFO or DEBUG")\args(1)

parser\option("-n --notifier", "Expects a path to a notifier moonscript file (overrides the default of ~/.spook/notifier.moon)")\args(1)

parser\option("-w --watch", "Expects path(s) to directories to watch (recursively)")\args("*")

parser\option("-c --config", "Expects the path to a Spook config file (eg. Spookfile) - overrides the default of loading a Spookfile from cwd")\args("1")

parser\option("-f --file", "Expects a path to a moonscript file - this runs the script within the context of spook, skipping the default behavior completely")\args(1)

parser\flag("-s --show-command", "Show the \"[RUNNING] path/to/utility path/to/file\" message on change detected")

parser
