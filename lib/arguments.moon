argparse = require "argparse"
parser = argparse name: "spook", description: "Your very own filesystem spymaster", epilog: "For more see https://github.com/johnae/spook"

parser\argument("command", "The command to run when a file changes")\args("+")

parser\flag("-v --version", "Show the Spook version you're running and exit")\action ->
  print(require "version")
  os.exit 0

parser\option("-l --log-level", "Log level, 0=ERROR, 1=WARN, 2=INFO, 3=DEBUG", "2")\convert(tonumber)

parser\option("-n --notifier", "Expects a path to a notifier moonscript (overrides the default of ~/.spook/notifier.moon)")\args(1)

parser\option("-m --mapping", "Expects a path to use as mapping (overrides the default of Spookfile)")\args(1)

parser
