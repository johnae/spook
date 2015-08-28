argparse = require "argparse"
parser = argparse name: "scare", description: "Interrogate that spymaster bastard", epilog: "For more see https://github.com/johnae/spook"

parser\argument("start", "The file to bootstrap from")\args("+")

parser
