argparse = require "argparse"

parser = argparse name: "spook", description: "Your very own filesystem spymaster", epilog: "For more see https://github.com/johnae/spook"

parser\argument("command", "Expects the command to run which will be given as input the output of the mapping (in Spookfile), enclose it in quotes!")\args("*")

parser\flag("-v --version", "Show the Spook version you're running and exit")\action ->
  print(require "version")
  os.exit 0

parser\flag("-i --initialize", "Initialize an example Spookfile in the current dir")\action ->
  f = io.open("Spookfile", "wb")
  content = [[
-- Directories to watch for changes
watch = {"app","lib","spec"}

-- How (changed) files are mapped to tests which become the input to the command to run
map = {
  "^(spec)/(spec_helper%.rb)": (a,b) -> "spec"
  "^spec/(.*)%.rb": (a,b) -> "spec/#{a}.rb"
  "^lib/(.*)%.rb": (a,b) -> "spec/lib/#{a}_spec.rb"
  "^app/(.*)%.rb": (a,b) -> "spec/#{a}_spec.rb"
}

-- You may also set the command to run here (as opposed to adding it on the command line), like this:
-- command = "./bin/rspec --tty -f d"
-- don't forget to return the command below like the others, eg. add :command to the returned values

:watch, :map]]
  content = f\write(content)
  f\close()
  os.exit 0

parser\option("-l --log-level", "Log level, 0=ERROR, 1=WARN, 2=INFO, 3=DEBUG", "2")\convert(tonumber)

parser\option("-n --notifier", "Expects a path to a notifier moonscript (overrides the default of ~/.spook/notifier.moon)")\args(1)

parser\option("-w --watch", "Expects path(s) to directories to watch (recursively) - this disables reading the dir list from stdin")\args("*")

parser\option("-c --config", "Expect the path to a Spook config file (eg. Spookfile) - overrides the default of loading a Spookfile from cwd")\args("*")

parser\option("-f --file", "Expects a path to moonscript file - this runs the script within the context of spook, skipping the default behavior")\args(1)

parser
