argparse = require "argparse"

parser = argparse name: "spook", description: "Your very own filesystem spymaster", epilog: "For more see https://github.com/johnae/spook"

parser\argument("command", "Expects the command to run which will be given as input the output of the mapping (in Spookfile), enclose it in quotes!")\args("*")

parser\flag("-v --version", "Show the Spook version you're running and exit")\action ->
  print(require "version")
  os.exit 0

parser\option("-l --log-level", "Log level, 0=ERROR, 1=WARN, 2=INFO, 3=DEBUG", "2")\convert(tonumber)

parser\option("-n --notifier", "Expects a path to a notifier moonscript (overrides the default of ~/.spook/notifier.moon)")\args(1)

parser\option("-w --watch", "Expects path(s) to directories to watch (recursively) - this disables reading the dir list from stdin")\args("*")

parser\option("-m --mapping", "Expects a path to use as mapping (overrides the default of Spookfile)")\args(1)

parser\option("-f --file", "Expects a path to moonscript file - this runs the script within the context of spook, skipping the default behavior")\args(1)

parser
