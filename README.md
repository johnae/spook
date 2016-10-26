[![Circle CI](https://circleci.com/gh/johnae/spook.svg?style=svg)](https://circleci.com/gh/johnae/spook)

## Some notes on the 0.7.0 version vs previous versions

This version has had it's innards ripped out and thrown away (so no more libuv/libluv). It's using just system calls now (so inotify, epoll and kqueue more or less directly). This was mainly so that I could enable more fine grained filesystem events watching. I also think this, in the end, will enable alot more use cases than as the lightweight [guard](https://github.com/guard/guard) replacement it originally was meant to be (it still works perfectly fine for that).

Unfortunately I haven't finished the BSD support (OS X included) in this version. What's lacking is a proper fs events watcher. It turned out that kqueue isn't as well suited to this as inotify on Linux is. It basically needs more code to work. Since I'm mostly a Linux user I haven't gotten around to really fixing this.

See the [CHANGELOG](CHANGELOG.md) for more information. The 0.6.x versions ofc work perfectly fine still.

## Spook

Spook used to be a light weight replacement for [guard](https://github.com/guard/guard) but is much more since the 0.7.0 version.
It's still early days but I'm using it every day for work. It is mostly written in [Lua](http://www.lua.org)
and [moonscript](https://github.com/leafo/moonscript) with a sprinkle of C. It's built as a single binary
with all dependencies built-in. The ridiculously fast [LuaJIT VM](http://luajit.org/) is embedded and compiled with Lua 5.2 compatibility. Extensions are easily written in [moonscript](https://github.com/leafo/moonscript),
which is also part of the binary.

You can download releases from [spook/releases](https://github.com/johnae/spook/releases). Currently only available for Linux x86_64. Compiling it is quite simple though and the only artifact is the binary itself which you can place wherever you like.

Buiding spook requires the usual tools (eg. make and gcc/clang), so you may need to install some things before building it. Otherwise it should be as straightforward as:

```
make
```

After that you should have an executable called spook. It's known to build on Linux and Mac OS X. In version 0.7.0 support for BSD/OSX is not complete wrt fs events and this makes it not very usable on those platforms (for now). Sorry. I will hopefully get around to that in time (or maybe you can help out?). The 0.6.0 and earlier releases should still work fine though.

Everything in the lib directory and toplevel is part of spook itself, anything in vendor and deps is other peoples work.


Installation is as straightforward as:

```
PREFIX=/usr/local make install
```

### Changelog

There's a [CHANGELOG](CHANGELOG.md) which may be useful when learning about any breaking changes, new features or other improvements. Please consult it when upgrading.


### Binaries

If you prefer to just install the latest binary you can do so by running the following in a shell:

```
curl https://gist.githubusercontent.com/johnae/6fdc84ea7d843812152e/raw/install.sh | PREFIX=~/Local bash
```

After running the above you should have an executable called spook. See below for instructions on how to run it.

You might want to check that script before you run it which you can do [here](https://gist.github.com/johnae/6fdc84ea7d843812152e).

Obviously you can also just download the release manually from the github releases page.


### Running it

For some basic help on command line usage, please run:

```
spook --help
```

Currently that would output something like:

```
Usage: spook [-v] [-i] [-l <log_level>] [-c <config>] [-w <dir>]
       [-f <file>] [-h]

Watches for events and runs functions (and commands) in response, based on a config file (eg. Spookfile)

Options:
   -v, --version         Show the Spook version you're running and exit
   -i, --initialize      Initialize an example Spookfile in the current dir
   -l <log_level>, --log-level <log_level>
                         Log level either ERR, WARN, INFO or DEBUG
   -c <config>, --config <config>
                         Expects the path to a Spook config file (eg. Spookfile) - overrides the default of loading a Spookfile from cwd
   -w <dir>, --dir <dir> Expects the path to working directory - overrides the default of using wherever spook was launched
   -f <file>, --file <file>
                         Expects a path to a moonscript file - this runs the script within the context of spook, skipping the default behavior completely
   -h, --help            Show this help message and exit.

For more see https://github.com/johnae/spook
```

### The Spookfile

To do anything useful you need to create a Spookfile in a directory (probably your project):

```
cd /to/your/project
spook -i
```

in your project directory to create an example Spookfile. Then tailor it to your needs. After that you just run spook without arguments in that directory. The default Spookfile is a basic example that might work for a Rails app.

The Spookfile should be written in [moonscript](https://github.com/leafo/moonscript). It comes with a simple DSL as well as just straight moonscript for just about anything you can do in Lua and/or MoonScript. Hooking in to the notifications api is easy and it's also easy to implement your own notifiers.

This is the Spookfile used to test spook itself:

```moonscript
-- How much log output can you handle? (ERR, WARN, INFO, DEBUG)
log_level "INFO"
load_spookfile = load_spookfile

-- If the spookfile is reloaded we just ensure we reload
-- the other stuff too.
package.loaded['moonscript.cmd.lint'] = nil
moonlint = require("moonscript.cmd.lint").lint_file
package.loaded.lint_config = nil
package.loaded.lint_config = pcall -> loadfile('lint_config')!

colors = require "ansicolors"
fs = require 'fs'

-- The terminal_notifier comes built-in, the 'notifier' however is
-- something just required from disk in the package.path.
notify = require('notify')!.add 'terminal_notifier', 'notifier'

-- spookfile_helpers is not included with the spook binary,
-- it's rather just some helpers in a file in this repo.
-- In general it's probably a good idea to keep helpers around
-- in some file you require. These helpers are generally very
-- useful in a test-runner context.
{
  :until_success
  :command
  :task_filter
  :notifies
} = require('spookfile_helpers')(notify)

-- we use this for notifications, by filtering out
-- the commands not runnable (because the mapped files
-- aren't present), we don't unnecessarily notify on
-- start / fail / success when nothing can actually
-- happen. For a spec runner, this makes sense.
task_list = task_filter fs.is_present
spec = command "./tools/luajit/bin/luajit spec/support/run_busted.lua"
exec = command "./tools/luajit/bin/luajit run.lua"

lint = (file) ->
  notify.info "LINTING #{file}"
  result, err = moonlint file
  success = if result
    io.stdout\write colors("\n[ %{red}LINT error ]\n%{white}#{result}\n\n")
    false
  elseif err
    io.stdout\write colors("\n[ %{red}LINT error ]\n#%{white}{file}\n#{err}\n\n")
    false
  else
    true
  if success
    io.stdout\write colors("\n[ %{green}LINT: %{white}All good ]\n\n")
  assert success == true, "lint #{file}"

-- Directories to watch for changes, how to map detected changes to
-- files and what to run
watch "lib", "spec", ->
  on_changed "^spec/spec_helper%.moon", (event) ->
    until_success ->
      notifies event.path, event,
        task_list(
          lint, "spec/spec_helper.moon"
          spec, "spec"
        )

  on_changed "^spec/(.*)%.moon", (event, name) ->
    until_success ->
      notifies event.path, event,
        task_list(
          lint, "spec/#{name}.moon"
          spec, "spec/#{name}.moon"
        )

  on_changed "^lib/(.*)/event_loop%.moon", (event, name) ->
    until_success ->
      notifies event.path, event,
        task_list(
          lint, "lib/#{name}/event_loop.moon"
          spec, "spec/event_loop_spec.moon"
        )

  on_changed "^lib/(.*)%.moon", (event, name) ->
    until_success ->
      notifies event.path, event,
        task_list(
          lint, "lib/#{name}.moon"
          spec, "spec/#{name}_spec.moon"
        )

watch "playground", ->
  on_changed "^playground/(.*)%.moon", (event, name) ->
      exec "playground/#{name}.moon"

  on_changed "^playground/(.*)%.lua", (event, name) ->
      exec "playground/#{name}.lua"

-- Reload spook when the Spookfile changes
watch_file 'Spookfile', ->
  on_changed (event) ->
    notify.info "Reloading Spookfile..."
    load_spookfile!

-- Reload spook when the lint_config file changes
watch_file 'lint_config.lua', ->
  on_changed (event) ->
    notify.info "Reloading Spookfile..."
    load_spookfile!
```

So as you can see, some things were defined in a helper file (until_success, notifies etc functions) and required from disk. Some others come built-in.

### Timers, Signals and Readers

Now for something completely different and slightly more experimental still. Perhaps you're not interested in file system events or perhaps you're interested in combining those events with other events on the system. Whatever you want, this is how you'd define a timer in the Spookfile:

```moonscript
timer 5.0, (t) ->
  print "yay I was called!"
  t\again! -- this is (currently) how a recurring timer is defined - just rearm it using the again method
```

For reading from stdin, this is what you do:

```moonscript
on_stdin (receiver, data) ->
  print "Incoming: #{data}"
```

And signal handlers are defined like this:

```moonscript
on_signal "int", (receiver) ->
  print "Why? Please don't interrupt me!"
```

Finally, reading from something else (like a socket) - please see the specs here [spec/event_loop_spec.moon](spec/event_loop_spec.moon). From the spookfile you'd do something like:

```moonscript
on_read some_fd, (data) ->
  print "Got some data: #{data}"
```

So, obviously it's very much up to you to get that FD from somewhere. These functions, eg. on_read, on_signal etc are actually methods on the global spook object. So, if you want to use them from a file you require you can do so like this instead:

```moonscript
-- it's really _G.spook
spook\on_read some_fd, (data) -> 
  print "Got some data: #{data}"
```

### Notifications

This is how a simple notifier might look (load it using notify.add):

```moonscript
-- "runs" is expected to return true or false and determines whether the notifier can run at all (eg. dependencies satisfied)
-- this way it's possible to put all kinds of notifiers in ~/.spook/notifiers and sync them across systems without
-- having to change the Spookfile.
getcwd = _G.getcwd
project_name = ->
  cwd = getcwd!\split '/'
  cwd[#cwd]

moon = require "moon"

-- info is a table
start = (msg, info) ->
  print "#{project_name!} starting: #{msg}"
  moon.p info -- debug

success = (msg, info) ->
  print "#{project_name!} success: #{msg}"
  moon.p info -- debug

fail = (msg, info) ->
  print "#{project_name!} fail: #{msg}"
  moon.p info -- debug

-- Finally those are exported in usual moonscript style
:start, :success, :fail
```

A notifier can use ANY arbitrary names for the functions handling the notifications. Just know that generally start, success and fail will be called. Whatever else you do is completely up to you. And you don't have to use any notifiers at all.

A slightly more complex notification example for tmux might look like this:

```moonscript
getcwd = _G.getcwd
round = math.round
project_name = ->
  cwd = getcwd!\split '/'
  cwd[#cwd]

time_calc = (start, finish) ->
  round finish - start, 3

tmux_set_status = (status) ->
  os.execute "tmux set status-left '#{status}' > /dev/null"

tmux_default_status = '#[fg=colour16,bg=colour254,bold]'

tmux_fail_status = (info) ->
  tmux_default_status .. '#[fg=white,bg=red] FAIL: ' .. project_name! .. " (#{time_calc(info.start_at, info.fail_at)} s) " .. '#[fg=red,bg=colour234,nobold]'

tmux_pass_status = (info) ->
  tmux_default_status .. '#[fg=white,bg=green] PASS: ' .. project_name! .. " (#{time_calc(info.start_at, info.success_at)} s) " .. '#[fg=green,bg=colour234,nobold]'

tmux_test_status = (info) ->
  tmux_default_status .. '#[fg=white,bg=cyan] TEST: ' .. project_name! .. ' #[fg=cyan,bg=colour234,nobold]'

spook = _G.spook

timer = nil
start = (msg, event) ->
  tmux_set_status tmux_test_status(event)
  timer\stop! if timer

success = (msg, info) ->
  tmux_set_status tmux_pass_status(info)
  timer\stop! if timer
  timer = spook\timer 7.0, (t) -> tmux_set_status tmux_default_status
  timer\start!

fail = (msg, info) ->
  tmux_set_status tmux_fail_status(info)
  timer\stop! if timer
  timer = spook\timer 7.0, (t) -> tmux_set_status tmux_default_status
  timer\start!

spook\on_signal 'int', (s) ->
  tmux_set_status tmux_default_status
  os.exit(1)

:start, :success, :fail
```

### Extending Spook

There's a package.path pointing to $HOME/.spook/lib as well as PROJECT_DIR/.spook/lib which means you can put any exensions in there (written in moonscript or lua) and load them easily from your Spookfile. This means you could extend functionality in infinite ways. This is really just convenience since you could just as easily add your own package paths directly to the Spookfile. However, to me it seems $HOME/.spook is a reasonable place to put such things as well PROJECT_DIR/.spook.

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

### License

Spook is released under the MIT license (see [LICENSE.md](LICENSE.md) for details).

### Contribute

Anything is welcome. Bug reports and pull requests most of all.

Use the [Github issue tracker](https://github.com/johnae/spook/issues) for bug reports please.
I can be reached directly at \<john at insane.se\> as well as through github.

### In closing

Anything you can do with LuaJIT (FFI for example) you can do in the notifier (or even Spookfile)  so go crazy if you want to.

MoonScript and Lua are really powerful and fun, coupled with LuaJIT they're ridiculously fast too compared to basically all other dynamic languages and runtimes. They're not used often enough in my opinion. You should really give them a try - they deserve it, regardless of whether you like Spook or not.
