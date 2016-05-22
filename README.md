[![Circle CI](https://circleci.com/gh/johnae/spook.svg?style=svg)](https://circleci.com/gh/johnae/spook)

## Spook

Spook is aiming to be a light weight replacement for [guard](https://github.com/guard/guard) and much more.
It's still early days but I'm using it every day for work. It is mostly written in [Lua](http://www.lua.org)
and [moonscript](https://github.com/leafo/moonscript) with a sprinkle of C. It's built as a single binary
with no external dependencies (it's not completely statically linked though). The ridiculously fast [LuaJIT VM](http://luajit.org/)
is embedded and compiled with Lua 5.2 compatibility. Extensions are easily written in [moonscript](https://github.com/leafo/moonscript),
which also comes bundled.

You can download releases from [spook/releases](https://github.com/johnae/spook/releases).
Currently only available for Linux x86_64.

Buiding spook requires the usual tools + cmake, so you may need to to apt-get/brew/yum/etc install cmake before
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

### Changelog

There's a [CHANGELOG](CHANGELOG.md) in in the repo which may be useful to learn about any breaking changes, new features or
other improvements. Please consult it when upgrading.


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
Usage: spook [-v] [-s] [-i] [-l <log_level>] [-n <notifier>]
       [-c <config>] [-f <file>] [-h]

Watches for changes and runs functions (and commands) in response, based on a config file (eg. Spookfile)

Options:
   -v, --version         Show the Spook version you're running and exit
   -s, --setup           Setup Spook - creates /home/john/.spook/notifiers and a default notifier (will overwrite /home/john/.spook/notifiers/default/terminal_notifier.moon)
   -i, --initialize      Initialize an example Spookfile in the current dir
   -l <log_level>, --log-level <log_level>
                         Log level either ERR, WARN, INFO or DEBUG
   -n <notifier>, --notifier <notifier>
                         Expects a path to a notifier moonscript file or a directory with notifiers
   -c <config>, --config <config>
                         Expects the path to a Spook config file (eg. Spookfile) - overrides the default of loading a Spookfile from cwd
   -w <dir>, --dir <dir> Expects the path to working directory - overrides the default of using wherever spook was launched
   -f <file>, --file <file>
                         Expects a path to a moonscript file - this runs the script within the context of spook, skipping the default behavior completely
   -h, --help            Show this help message and exit.

For more see https://github.com/johnae/spook
```

### First things first

It's a good idea to first run spook with the setup switch on a new system. The way you do that is to just run:

```
spook --setup
```

That creates $HOME/.spook/notifiers/default/terminal_notifier.moon (and the needed directories). It's useful to keep that
even when you create your own notifiers. It provides meaningful terminal output even though you might also want say OS X
notifications, growl notifications or some other type of notifier (like a tmux notifier or linux notifier using notify-send).
For your own notifiers, just create directories under $HOME/.spook/notifiers and place your notifiers there. Any notifiers
from any sub-directories will automatically load.


### The Spookfile

To watch directories you need to initialize a Spookfile in your project. It will currently create one tailored to a Rails app but
should be pretty straightforward to change according to your needs. Just run:

```
cd /to/your/project
spook -i
```

in your project directory to initialize a Spookfile. Then tailor it to your needs. After that you can just run spook without arguments within
that directory. The default Spookfile is a basic example that would work for a Rails app.

The Spookfile is written as [moonscript](https://github.com/leafo/moonscript) and maps files to functions. It understands a simple
DSL as well as just straight moonscript for additional things. There's a command helper for when a shell command should run in
response to a change (which is probably the most common use case). Hooking in to the notifications api is recommended and is
automatic when using the command helper. The command helper supports one option - only_if. It can be used like this:

```
fs = require "fs"
cmd = command "ls -lah", only_if: fs.is_present
```

So basically only_if should be a function, the only argument it gets is the mapped file. If only_if returns true, the
command will run - otherwise it won't. The default is actually the above - the command won't run if the file doesn't
exist. Clearly you could write whatever function you want but usually in my experience the default is what you want.

See below for more information on how all this works.

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
-- file_handler = func name: "file_handler", handler: (file, info) ->
--   -- the file parameter here is whatever on_changed gives the file_handler
--   -- the info parameter is a table containing "changed_file" and "mapped_file".
--   -- mapped_file is the same as the input parameter "file" and "changed_file" is
--   -- of course whatever file was changed.
--   f = assert io.open(file, 'r')
--   content = f\read!
--   f\close!
--   new_content = "do stuff do content: #{content}"
--   o = assert io.open('/tmp/new_file.txt', 'w')
--   o\write new_content
--   o\close!
--   true -- return true or false depending on whether this was a success
--
-- watch "stuff", ->
--   on_changed "stuff/(.*)/(.*)%.txt", (a, b) -> file_handler "stuff/#{a}/#{b}.txt"

-- Define notifiers to use, a default one (including directory structure) is created for you
-- when you run "spook --setup". All notifiers in specified dir are loaded and if their "runs"
-- function returns true they will be run (if there is no runs function they will also run).
-- Set log_level to DEBUG to see whether there's a failure in loading them. Either
-- through command line switch -l or in this file.
notifier "#{os.getenv('HOME')}/.spook/notifiers"

-- You can even specify a notifier right here (perhaps for simpler variants), like:
--notifier {
--  start: (info) ->
--    print "changed_file: #{info.changed_file}"
--    print "#{info.description}"
--  finish: (success, info) ->
--    print "changed_file: #{info.changed_file}"
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
--
--
-- commands and functions can be added together to run all of them in serial. If a cmd or
-- function fails (non true return value), any later ones are skipped and the error is reported
-- to the notifier.
cmd1 = command "ls -lah"
cmd2 = command "echo [file]"
file_handler = func name: "file_handler", handler: (file) ->
  f = assert io.open(file, 'r')
  content = f\read!
  f\close!
  new_content = "do stuff do content: #{content}"
  o = assert io.open('/tmp/new_file.txt', 'w')
  o\write new_content
  o\close!
  true -- return true or false for notications

watch "some_place", ->
  on_changed "^some_place/(.*)/(.*).txt", (a, b) ->
    cmd1("stuff/#{a}/#{b}_thing.txt") +
    cmd2! +
    file_handler "some/other/#{a}/#{b}_thing.txt"
```

### Motivating example of a func handler

Let's say we have a project written in moonscript. However we want to to always include the
lua version since not everyone likes moonscript and/or don't want to include moonscript as a
project dependency. What I've seen is that people may use [Tup](http://gittup.org/tup/index.html)
which is a fine tool indeed. However, you can have similar functionality using Spook and you can
ensure relevant tests and linting are always run before the compile step. So how could we implement
something like that? Well, it's not that hard and Spook comes with moonscript built in. Here goes:

```moonscript
log_level "INFO"

colors = require "ansicolors"
lint = require("moonscript.cmd.lint").lint_file
to_lua = require("moonscript").to_lua

spec_cmd = command "busted spec"

lint_cmd = func name: "Lint", handler: (file) ->
  result, err = lint file
  if result
    io.stdout\write colors("\n[ %{red}LINT error ]\n%{white}#{result}\n\n")
    return false
  elseif err
    io.stdout\write colors("\n[ %{red}LINT error ]\n#%{white}{file}\n#{err}\n\n")
    return false
  io.stdout\write colors("\n[ %{green}LINT: %{white}All good ]\n\n")
  true

to_lua_cmd = func name: "Compile lua", handler: (newname, ev) ->
  changed_file = ev.changed_file
  moonfile = io.open(changed_file)
  content = moonfile\read "*a"
  moonfile\close!
  as_lua, line_table = to_lua content
  unless as_lua
    io.stdout\write colors("\n[ %{red}Compile to lua error in #{changed_file} ]\n%{white}#{line_table}\n\n")
    return false
  io.stdout\write colors("\n[ %{green}Compiled #{changed_file} to lua file #{newname}: %{white}All good ]\n\n")
  lua_file = io.open(newname, 'w+')
  lua_file\write as_lua
  lua_file\close!
  true

-- Setup what directories to watch and what to do
-- when a file is changed. "command" is a helper
-- for setting up what command to run. There is no
-- restriction on running shell commands however -
-- any function (in lua/moonscript) can be run
watch "lib", "spec", ->
  on_changed "^(spec)/(spec_helper%.moon)", -> spec_cmd "spec"
  on_changed "^spec/(.*)_spec%.moon", (a) ->
    lint_cmd("spec/#{a}_spec.moon") +
    spec_cmd("spec/#{a}_spec.moon")
-- here we want to compile to lua as well
  on_changed "^lib/(.*)%.moon", (a) ->
    lint_cmd("lib/#{a}_spec.moon") +
    spec_cmd("spec/#{a}_spec.moon") +
    to_lua_cmd("lib/#{a}.lua")

```

And that's that. The above example also demonstrates that you really can include any library or
code you want in the Spookfile. Of course, you may want to create separate files at some point and
only require them from the Spookfile to prevent the Spookfile getting bloated.


### Notifications

The default Spookfile that is generated via ```spook -i``` defines notifiers
to be loaded from ```$HOME/.spook/notifiers```, where you actually put them
is irrelevant however but it's probably a good place for them - others working
on a project might want different notifiers while still checking in the Spookfile
in the repo. Using "commands" automatically ties into the the notifier api. For your
own functions you have to do this yourself if you want/need notifications (see above for example).

All notifiers under the directory (or any subdirs) defined in the Spookfile will be loaded as long
as their "runs" function returns true or if the "runs" function is missing (probably best to define
it regardless). Loading from all subdirs under ~/.spook/notifiers enables certain uses like cloning/updating
different git-repos for different notifiers without clobbering any others.

This is how a simple notifier might look:

```moonscript
-- "runs" is expected to return true or false and determines whether the notifier can run at all (eg. dependencies satisfied)
-- this way it's possible to put all kinds of notifiers in ~/.spook/notifiers and sync them across systems without
-- having to change the Spookfile.
runs = -> true

start = (info) ->
  print "#{project_name!}: running #{info.description}"

finish = (success, info) ->
  if success
    print "#{project_name!}: run of '#{info.description}' passed in #{info.elapsed_time} seconds"
  else
    print "#{project_name!}: run of '#{info.description}' failed in #{info.elapsed_time} seconds"

-- Finally those are exported in usual moonscript style
:start, :finish, :runs
```

You must define at a minimum "start" or "finish" and export them or your notifier will not run at all.

A more complex notification example for tmux might look like this (the uv package comes built in):

```moonscript
uv = require "uv"

tmux_set_status = (status) ->
  os.execute "tmux set status-left '#{status}' > /dev/null"

tmux_default_status = '#[fg=colour16,bg=colour254,bold]'

tmux_fail_status = (info) ->
  tmux_default_status .. '#[fg=white,bg=red] FAIL: ' .. project_name! .. " (#{info.elapsed_time} s) " .. '#[fg=red,bg=colour234,nobold]'
tmux_pass_status = (info) ->
  tmux_default_status .. '#[fg=white,bg=green] PASS: ' .. project_name! .. " (#{info.elapsed_time} s) " .. '#[fg=green,bg=colour234,nobold]'
tmux_test_status = ->
  tmux_default_status .. '#[fg=white,bg=cyan] TEST: ' .. project_name! .. ' #[fg=cyan,bg=colour234,nobold]'

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

-- only run this notifier if the TMUX env var is set
runs = -> os.getenv("TMUX")

start = (info) ->
  tmux_set_status tmux_test_status!
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

finish = (success, info) ->
  if success
    tmux_set_status tmux_pass_status(info)
  else
    tmux_set_status tmux_fail_status(info)

  start_reset_timer!

:start, :finish, :runs
```

There's a gist for the above I just clone to ~/.spook/notifiers/tmux here: [tmux notifier gist](https://gist.github.com/johnae/fc8e04acef49999fc5c9)

There is also an OS X example here using terminal-notifier for system notifications: [osx notifier gist](https://gist.github.com/fc803fe80124a0fe1953)

And finally an Ubuntu example using notify-send here: [ubuntu notifier gist](https://gist.github.com/johnae/ba58535c58bbeccea288)


You may also use the commandline switch -n to add/test a notifier:

```
spook -n /path/to/some/notifier.moon
```

### Extending Spook

There's a package.path pointing to $HOME/.spook/lib as well as PROJECT_DIR/.spook/lib which means you can put any exensions in there (written
in moonscript or lua) and load them easily from your Spookfile. This means you could extend functionality in infinite ways. This is really
just convenience since you could just as easily add your own package paths directly to the Spookfile. However, to me it seems $HOME/.spook
is a reasonable place to put such things as well PROJECT_DIR/.spook.

Basically, let's say you've got some code in $HOME/.spook/lib/utils/boom.moon that you'd like to use in the Spookfile. This is how you'd do that:

```moonscript
boom = require "utils.boom"

boom.blow_up!
```

That _may_ be overridden by a local file in PROJECT_DIR/.spook/lib which takes precedence (eg. named the same as the one in the global search path).


### Additional functions available in the global scope

These can be used in the notifier and any other code running in the context of spook (like stuff in $HOME/.spook/lib or code in the Spookfile):

```moonscript
getcwd
```

Change the working directory.

```moonscript
chdir("/some/dir")
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
