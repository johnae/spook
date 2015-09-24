[![Circle CI](https://circleci.com/gh/johnae/spook.svg?style=svg)](https://circleci.com/gh/johnae/spook)

## Spook

Spook is aiming to be a light weight replacement for [guard](https://github.com/guard/guard).
It's still early days but I'm using it every day for work. It is mostly written in [Lua](http://www.lua.org)
and [moonscript](https://github.com/leafo/moonscript) with a sprinkle of C. It's built as a static
binary with no dependencies. The ridiculously fast [LuaJIT VM](http://luajit.org/) is embedded and
compiled with Lua 5.2 compatibility. All extensions and such should be written in [moonscript](https://github.com/leafo/moonscript).

You can download releases from [spook/releases](https://github.com/johnae/spook/releases).
Currently only available for Linux x86_64 and Mac OS X x86_64.

Building it should be as straightforward as:

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
       [-f <file>] [-s] [-h] [<command>]

Watches for changes and runs commands in response

Arguments:
   command               Expects the command to run which will be given as input the output of the mapping (in Spookfile), enclose it in quotes!

Options:
   -v, --version         Show the Spook version you're running and exit
   -i, --initialize      Initialize an example Spookfile in the current dir
   -l <log_level>, --log-level <log_level>
                         Log level either ERR, WARN, INFO or DEBUG
   -n <notifier>, --notifier <notifier>
                         Expects a path to a notifier moonscript file (overrides the default of ~/.spook/notifier.moon)
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

This file is written as [moonscript](https://github.com/leafo/moonscript) and maps files to other files among other things. It understands a simple
DSL as well as just straight moonscript for additional things.

A functional example of mapping etc via the Spookfile (for a rails app in this case) might be:

```moonscript
-- How much output do you want? (ERR, WARN, INFO, DEBUG)
log_level "INFO"

-- Set up watches for one or more directories and associate
-- mapping with those watches. A function is associated with
-- the matcher and will run on changes. The command helper is
-- there so it's easy to construct a function that runs a shell command
-- but it's not limited to that - you can run any function you want.
watch "lib", "spec", ->
  cmd "./spook -f spec/support/run_busted.lua", show_command: true -- setting show_command means it will log what it runs
  on_changed "^(spec)/(spec_helper%.moon)", -> cmd "spec"
  on_changed "^spec/(.*)%.moon", (a) -> cmd "spec/#{a}.moon"
  on_changed "^lib/(.*)%.moon", (a) -> cmd "spec/#{a}_spec.moon"

-- Another watch
watch "playground", ->
  cmd = command "./spook -f"
  on_changed "^playground/(.*)%.moon", (a) -> cmd "playground/#{a}.moon"

-- The notifier to use
notifier "#{os.getenv('HOME')}/.spook/notifier.moon"
```

### Notifications

If you create a directory called .spook in your home dir and put a file called notifier.moon in there it will be loaded
and called by spook when certain events take place. The events supported are "start" and "finish".
Something like this in ~/.spook/notifier.moon:

```moonscript
start = (changed_file, mapped_file) ->
  print "#{project_name!}: running specs #{mapped_file} for changes in #{changed_file}"

finish = (success, changed_file, mapped_file) ->
  if success
    print "#{project_name!}: tests in #{mapped_file} for changes in #{changed_file} passed"
  else
    print "#{project_name!}: tests in #{mapped_file} for changes in #{changed_file} failed"

:start, :finish
```

You must currently define both of the above functions and export them or things will crash and burn (you CAN skip
creating the notifier completely though).

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

start = (changed_file, mapped_file) ->
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

finish = (success, changed_file, mapped_file) ->
  if success
    tmux_set_status tmux_pass_status
  else
    tmux_set_status tmux_fail_status

  start_reset_timer!

:start, :finish
```

There's a gist for the above I just clone to ~/.spook here: [tmux notifier gist](https://gist.github.com/johnae/fc8e04acef49999fc5c9)

There is also an OS X example here using terminal-notifier for system notifications: [osx notifier gist](https://gist.github.com/fc803fe80124a0fe1953)


You may also use the commandline switch -n to override this:

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

Anything you can do with LuaJIT (FFI for example) you can do in the notifier so go crazy if you want to.

MoonScript and Lua are really powerful and fun, coupled with LuaJIT they're ridiculously fast but often overlooked languages.
You should really give them a try - they deserve it, regardless of whether you like Spook or not.
