[![Circle CI](https://circleci.com/gh/johnae/spook.svg?style=svg)](https://circleci.com/gh/johnae/spook)

## Spook

Spook is aiming to be a light weight replacement for [guard](https://github.com/guard/guard) and much more.
It's still early days but I'm using it every day for work. It is mostly written in [Lua](http://www.lua.org)
and [moonscript](https://github.com/leafo/moonscript) with a sprinkle of C. It's built as a static
binary with no external dependencies. The ridiculously fast [LuaJIT VM](http://luajit.org/) is embedded and
compiled with Lua 5.2 compatibility. Extensions easily written in [moonscript](https://github.com/leafo/moonscript).

You can download releases from [spook/releases](https://github.com/johnae/spook/releases).
Currently only available for Linux x86_64 and Mac OS X x86_64.

Buiding spook requires the usual tools + cmake, so you may need to to apt-get install cmake before
building it. Otherwise it should be as straightforward as:

```
make
```

After that you should have an executable called spook. It's known to build on Linux and Mac OS X.
Everything in the lib directory and toplevel is part of spook itself, anything in vendor and deps
is other peoples work and is just included in the resulting executable.


Installation is as straightforward as:

```
PREFIX=/usr/local make install
```

### Binaries

If you prefer to just install the latest binary you can do so by running the following in a shell:

```
curl https://gist.githubusercontent.com/johnae/6fdc84ea7d843812152e/raw/install.sh | PREFIX=~/Local bash
```

After running the above you should have an executable called spook. See below for instructions on how to run it.

You might want to check that script before you run it which you can do [here](https://gist.github.com/johnae/6fdc84ea7d843812152e)

### Running it

For some basic help on command line usage, please run:

```
spook --help
```

Currently that would output something like:

```
Usage: spook [-v] [-i] [-l <log_level>] [-n <notifier>] [-c <config>]
       [-f <file>] [-h] [<command>]

Watches for changes and runs functions (and commands) in response

Arguments:
   command               Expects the command to run which will be given as input the output of the mapping (in Spookfile), enclose it in quotes!

Options:
   -v, --version         Show the Spook version you're running and exit
   -i, --initialize      Initialize an example Spookfile in the current dir
   -l <log_level>, --log-level <log_level>
                         Log level either ERR, WARN, INFO or DEBUG
   -n <notifier>, --notifier <notifier>
                         Expects a path to a notifier moonscript file
   -c <config>, --config <config>
                         Expects the path to a Spook config file (eg. Spookfile) - overrides the default of loading a Spookfile from cwd
   -f <file>, --file <file>
                         Expects a path to a moonscript file - this runs the script within the context of spook, skipping the default behavior completely
   -h, --help            Show this help message and exit.

For more see https://github.com/johnae/spook
```

To watch directories you need to initialize a Spookfile in your project. It will currently create one tailored to a Rails app but
should be pretty straightforward to change according to your needs. Just run:

```
spook -i
```

in your project directory to initialize a Spookfile. Then tailor it to your needs. After that you can just run spook without arguments within
that directory.

### The Spookfile

The Spookfile can, as mentioned above, be initialized (with an example for a Rails app) like this:

```
cd /to/your/project
spook -i
```

This file is written as [moonscript](https://github.com/leafo/moonscript) and maps files to functions. It understands a simple
DSL as well as just straight moonscript for additional things. There's a command helper for when a shell command should run in
response to a change. Hooking in to the notifications api is recommended and is automatic when using the command helper. See
below for more information on how all this works.

A functional example of mapping etc via the Spookfile (for a rails app in this case) might be:

```moonscript
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
-- {:round} = math
-- handle_file = (file) ->
--   f = assert io.open(file, 'r')
--   content = f\read!
--   f\close!
--   new_content = "do stuff to content: #{content}"
--   o = assert io.open('/tmp/new_file.txt', 'w')
--   o\write new_content
--   o\close!
--   true -- return true or false for notifications
-- do_stuff = (file) ->
--   notify.start "do_stuff", file -- for terminal etc notifications
--   ts = gettimeofday! / 1000.0
--   success = handle_file file
--   te = gettimeofday! / 1000.0
--   elapsed = round te - ts, 3
--   notify.finish success, "do_stuff", file, elapsed -- for terminal etc notifications
--
-- watch "stuff", ->
--   on_changed "stuff/(.*)/(.*)%.txt", (a, b) -> do_stuff "stuff/#{a}/#{b}.txt"

-- Define additional notifiers to use. Any number of them can be specified here (by
-- just issuing the notifier config command again).
-- Set log_level to DEBUG to see whether there's a failure in loading them. Either
-- through command line switch "-l DEBUG" or in this file.
notifier "#{os.getenv('HOME')}/.spook/notifier.moon"

-- You can even specify a notifier right here (perhaps for simpler variants), like:
--
--notifier {
--  start: (what, data) ->
--    print "#{what} "#{data}"
--  finish: (success, what, data, elapsed_time) ->
--    if success
--      print "Success! in #{elapsed_time} s"
--    else
--      print "Failure! in #{elapsed_time} s"
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
```

### Notifications

The default Spookfile that is generated via ```spook -i``` defines a notifier
to be loaded from ```$HOME/.spook/notifier.moon```, where you actually put them
is irrelevant however but it's probably as good a place as any - others working
on a project might want different notifiers while still checking in the Spookfile
in the repo. Using "commands" automatically ties into the the notifier api, for your
own functions you have to do this if you want/need notifications (see above for example).
This is how a simple notifier might look:

```moonscript
-- The "what" for commands is the command specified, the "data" is the mapped file.
start = (what, data) ->
  print "#{project_name!}: changes detected in #{changed_file}"

finish = (success, what, data, elapsed_time) ->
  if success
    print "#{project_name!}: run of '#{what} #{data}' passed in #{elapsed_time} seconds"
  else
    print "#{project_name!}: run of '#{what} #{data}' failed in #{elapsed_time} seconds"

:start, :finish
```

You must define both of the above functions and export them or things will crash and burn.

A more complex notification example for tmux might look like this (the uv package comes built in):

```moonscript
uv = require "uv"

tmux_set_status = (status) ->
  os.execute "tmux set status-left '#{status}' > /dev/null"

tmux_default_status = '#[fg=colour16,bg=colour254,bold]'

tmux_fail_status = tmux_default_status .. '#[fg=white,bg=red] FAIL: ' .. project_name! .. ' #[fg=red,bg=colour234,nobold]'
tmux_pass_status = tmux_default_status .. '#[fg=white,bg=green] PASS: ' .. project_name! .. ' #[fg=green,bg=colour234,nobold]'
tmux_test_status = tmux_default_status .. '#[fg=white,bg=cyan] TEST: ' .. project_name! .. ' #[fg=cyan,bg=colour234,nobold]'

timer = nil
stop_timer = ->
  if timer
    timer\stop!
    timer\close!
    timer = nil

start_reset_timer = ->
  stop_timer!
  uv.update_time!
  timer = uv.new_timer!
  timer\start 7000, 0, ->
    tmux_set_status tmux_default_status
    stop_timer!

start = (what, data) ->
  tmux_set_status tmux_test_status
  start_reset_timer!

-- we can use uv:s signal handling to ensure something runs
-- if you press ctrl-c for example, here we ensure tmux status
-- line is reset to it's original state before exiting spook
sigint = uv.new_signal!
uv.signal_start sigint, "sigint", (signal) ->
  print "got #{signal}, shutting down"
  stop_timer!
  tmux_set_status tmux_default_status
  os.exit 1

finish = (success, what, data, elapsed_time) ->
  if success
    tmux_set_status tmux_pass_status
  else
    tmux_set_status tmux_fail_status

  start_reset_timer!

:start, :finish
```

There's a gist for the above I just clone to ~/.spook here: [tmux notifier gist](https://gist.github.com/johnae/fc8e04acef49999fc5c9)

There is also an OS X example here using terminal-notifier for system notifications: [osx notifier gist](https://gist.github.com/fc803fe80124a0fe1953)


You may also use the commandline switch -n to add a notifier:

```
spook -n /path/to/some/notifier.moon
```

### Additional functions available in the global scope

These can be used in the notifier:

```moonscript
getcwd
```

This returns the current working directory (where you run spook, probably your git checkout of your app).

```moonscript
project_name
```

This just returns the directory basename of your checkout - if you're sane it will be your project name.

```moonscript
git_branch
```

This gets you the branch you're on.

```moonscript
git_tag
```

This gets you the tag you're on or nil if you're not on a tagged commit.

```moonscript
git_ref
```

This gets you either the tag (if you're on a tagged commit) or the branch.

```moonscript
git_sha
```

This gets you the short sha of HEAD.

### License

Spook is released under the MIT license (see [LICENSE.md](LICENSE.md) for details).

### Contribute

Anything is welcome. Bug reports and pull requests most of all.

Use the [Github issue tracker](https://github.com/johnae/spook/issues) for bug reports please.
I can be reached directly at \<john at insane.se\> as well as through github.

### In closing

Anything you can do with LuaJIT (FFI for example) you can do in the notifier (or even Spookfile)  so go crazy if you want to.

MoonScript and Lua are really powerful and fun, coupled with LuaJIT they're ridiculously fast but often overlooked languages.
You should really give them a try - they deserve it, regardless of whether you like Spook or not.
