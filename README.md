[![Circle CI](https://circleci.com/gh/johnae/spook.svg?style=svg)](https://circleci.com/gh/johnae/spook)
[![Travis CI](https://travis-ci.org/johnae/spook.svg?branch=master)](https://travis-ci.org/johnae/spook)

## Spook

Spook started out as a light weight replacement for [guard](https://github.com/guard/guard) but has become more than that over time. It is mostly written in [MoonScript](https://github.com/leafo/moonscript), a language that compiles to [Lua](http://www.lua.org) - with a sprinkle of C. It's built as a single binary. The ridiculously fast [LuaJIT VM](http://luajit.org/) is embedded and compiled with Lua 5.2 compatibility. Extensions are easily written in [MoonScript](https://github.com/leafo/moonscript), which is also part of the binary.

While spook may seem to be geared towards running tests in a feedback loop, there are many other potential uses. For some inspiration, check out my i3bar implementation [moonbar](https://github.com/johnae/moonbar) for the [i3 window manager](https://i3wm.org/) which is also using a Spookfile but in most other ways is doing something very different. Otherwise the Spookfile in this repo and the examples in the readme should point you in the right direction if you're just looking for a lightweight test runner.

Spook was also somewhat inspired by the [entrproject](http://entrproject.org/) and it's simplicity (eg. the lightweight "feel" of entr). However the goal of spook was always broader and more general. Still, entr is a very nice tool which is why spook has (since version 0.8.1) gained the basic functionality entr provides - namely: read a list of files on stdin and run a command when any of them changes. It's a bonus feature for one off tasks more than anything else. See far down for some examples.

Building spook requires the usual tools (eg. make and gcc/clang), so you may need to install some things before building it. Otherwise it should be as straightforward as:

```sh
make
```

After that you should have an executable called spook. It's known to build and work well on Linux and Mac OS X. It's also verified to work on FreeBSD. On FreeBSD, you need to install gmake, like this:

```sh
sudo pkg install gmake
gmake
```

Everything in the lib directory and top level is part of spook itself, anything in vendor and deps is other peoples work.


Installation is as straightforward as:

```sh
make install PREFIX=/usr/local
```

Or gmake on FreeBSD for example.

### Changelog

There's a [CHANGELOG](CHANGELOG.md) which may be useful when learning about any breaking changes, new features or other improvements. Please consult it when upgrading.

### Binaries

There used to be binaries for Linux x86_64 but that stopped as of 0.8.4. It's very simple to build spook so just clone the source and follow the above procedure on building.

### Running it

For some basic help on command line usage, please run:

```sh
spook --help
```

Currently that would output something like:

```
Usage: spook [-v] [-i] [-l <log_level>] [-c <config>] [-w <dir>]
       [-f <file>] [-s] [-o] [-h]

Watches for changes and runs functions (and commands) in response, based on a config file (eg. Spookfile)

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
   -s                    In entr mode, start the given utility immediately without waiting for changes first - can't be used with -o
   -o                    In entr mode, exit immediately after running utility - can't be used with -s
   -h, --help            Show this help message and exit.

For more see https://github.com/johnae/spook
```

### MacOS

Check your ulimits. If set to a small value it will likely make spook crash. Setting it higher looks something like:

```sh
ulimit -n 4096
```

Here's a guide on how to permanently set your ulimits on MacOS: [ulimit-shenanigans-on-osx-el-capitan](https://blog.dekstroza.io/ulimit-shenanigans-on-osx-el-capitan/)

### The Spookfile

To do anything useful you need to create a Spookfile in a directory (probably your project):

```sh
cd /to/your/project
spook -i
```

in your project directory to create an example Spookfile. Then tailor it to your needs. After that you just run spook without arguments in that directory. The default Spookfile is a basic example that might work for a Rails app.

The Spookfile should be written in [MoonScript](https://github.com/leafo/moonscript). It comes with a simple DSL as well as just straight MoonScript for just about anything you can do in Lua and/or MoonScript. Hooking in to the notifications api is easy and it's also easy to implement your own notifiers.

This is the Spookfile used to test spook itself:

```moonscript
-- How much log output can you handle? (ERR, WARN, INFO, DEBUG)
log_level "INFO"

-- If the spookfile is reloaded we just ensure we reload
-- the other stuff too.
package.loaded['moonscript.cmd.lint'] = nil
moonlint = require("moonscript.cmd.lint").lint_file
package.loaded.lint_config = nil
package.loaded.lint_config = pcall -> loadfile('lint_config')!

-- Require some things that come with spook
colors = require "ansicolors"
fs = require 'fs'

-- Adds the built-in terminal_notifier - this notifies of success/fail
-- in the terminal.
notify.add 'terminal_notifier'

-- If we find 'notifier' in the path, let's
-- add that notifier also. We fail silently otherwise.
pcall notify.add, 'notifier'

-- Yet another simple way of including a notifier would
-- be to define it right here - like this:
notify.add {
  start: (msg, info) ->
    print "Start, yay"
  success: (msg, info) ->
    print "Success, yay!"
  fail: (msg, info) ->
    print "Fail, nay!"
}

-- spookfile_helpers is included inside the spook binary,
-- it's some helpers mainly for using spook in a similar fashion
-- to guard.
{
  :until_success
  :command
  :task_filter
  :notifies
} = require 'spookfile_helpers'

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

-- Watching for changes underneath . and matching them to handlers using
-- lua patterns (see: http://lua-users.org/wiki/PatternsTutorial for example).
watch ".", ->

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

  on_changed "^shpec/(.*)%.sh", (event, name) ->
    return unless os.getenv('SPOOK_INTEGRATION') == 'yes'
    until_success ->
      notifies event.path, event,
        task_list(
          shpec, "shpec/#{name}.sh"
        )

  on_changed "^playground/(.*)%.moon", (event, name) ->
    exec "playground/#{name}.moon"

  on_changed "^playground/(.*)%.lua", (event, name) ->
    exec "playground/#{name}.lua"

  on_changed "^Spookfile$", (event) ->
    notify.info "Re-executing spook..."
    reload_spook!

  on_changed "^lint_config%.lua$", (event) ->
    notify.info "Re-executing spook..."
    reload_spook!
```

So as you can see, some things were defined in a helper file (until_success, notifies etc functions) and required from disk. Some others come built-in.

Of note is that while it's possible to define several watch statements with different directories, as soon as you want to watch something in PWD (that goes for watch_file statements as well even though non-obvious) it's better to just watch '.' and define on_changed handlers (or on_deleted, on_attrib, on_created etc.) to match on them.

The reason for this is that the matchers are all in the same "bucket" and it's more straightforward to ensure no collisions eg. something unexpected matches before the match you expected - spook ONLY executes the handler for the first match by default.

Basically instead of this:

```moonscript
watch 'lib', 'spec', ->
  on_changed '^lib/(.*)%.moon', (event, name) ->
    run_spec "spec/#{name}_spec.moon"

  on_changed '^spec/(.*)%.moon', (event, name) ->
    run_spec "spec/#{name}.moon"

-- anything we may easily assume
  on_changed '.*', (event) ->
    print "something changed"

-- this will never run because the above catch-all will be matched -
-- at the moment all matchers are in the same "bucket".
watch_file 'spookfile', ->
  on_changed (event) ->
    notify.info "re-executing spook..."
    reload_spook!
```

Do this:

```moonscript
watch '.', ->
  on_changed '^lib/(.*)%.moon', (event, name) ->
    run_spec "spec/#{name}_spec.moon"

  on_changed '^spec/(.*)%.moon', (event, name) ->
    run_spec "spec/#{name}.moon"

  on_changed '^Spookfile$', (event) ->
    notify.info "re-executing spook..."
    reload_spook!

-- anything else - this would actually work as expected
  on_changed '.*', (event) ->
    print "something changed"
```

### Adding a simple REPL

As of Spook 0.8.4 there is a basic implementation of a REPL that can also be extended quite easily. To use the repl you would do something like this in the Spookfile:

```moonscript
-- the function given to the shell below is the prompt, it should be a function
-- it is called on every screen update.
:repl = require('shell') -> getcwd! .. ' spook% '
S = require 'syscall'
on_read S.stdin, repl
```

Press enter and the repl will present itself. Type "help" for a list of default commands. Defining more commands work like this:

```moonscript
:repl, :cmdline = require('shell') -> getcwd! .. ' spook% '
S = require 'syscall'

-- the first argument is the command name, second the help text
cmdline\cmd "date", "Show the current date", (screen) ->
  print os.date!

-- the arguments given to the function (last arg) are first the
-- screen object which may or may not be very interesting. The
-- following arguments are whatever is given after the name of
-- the command tokenized using space as delimiter.
cmdline\cmd "date", "Show the current date", (screen) ->
  print os.date!

:concat = table
cmdline\cmd "echo", "Echo whatever you want", (screen, ...) ->
  args = {...}
  str = concat args, '#'
  print str
-- examples of the output of above:
-- echo one two three
-- one#two#three

-- it's possible to define a dynamic handler that would be a catchall for
-- anything not defined, like this:
cmdline\dynamic (c, key, value) ->
  (screen, ...) ->
    args = {key}
    insert args, arg for arg in *{...}
    os.execute concat(args, ' ')
-- above would try to execute anything not already defined
-- as a program on the PATH

on_read S.stdin, repl
```

### Timers, Signals and Readers

Now for something completely different and slightly more experimental still. Perhaps you're not interested in file system events or perhaps you're interested in combining those events with other events on the system. Whatever you want, this is how you'd define a timer in the Spookfile:

```moonscript
after 5.0, (t) ->
  print "yay I was called!"
  t\again! -- this would be a somewhat inefficient way of creating a recurring timer (needs a syscall)
```

As mentioned above, recurring timers using "again" are somewhat inefficient. It's probably better to use the "every" function instead in that case:

```moonscript
every 5.0, (t) ->
  print "this will print every 5 seconds"
```

There is also the old function "timer" which behaves exactly like "after" above.

And signal handlers are defined like this:

```moonscript
on_signal "int", (receiver) ->
  print "Why? Please don't interrupt me!"
  os.exit(1) -- you should probably deal with this in a sane way
```

Finally, reading from something else (like a socket) - please see the specs here [spec/event_loop_spec.moon](spec/event_loop_spec.moon). From the spookfile you'd do something like:

```moonscript
S = require 'syscall'
stdin = S.stdin
on_read stdin, (reader, fd) ->
  data = fd\read!
  print "Got some data: #{data}"
```

These functions, eg. on_read, on_signal etc are actually methods on the global spook object. So, if you want to use them from a file you require you can do so like this instead:

```moonscript
S = require 'syscall'
stdin = S.stdin
-- stdin = Types.fd(0) - if it's some other fd you MUST wrap it (S.stdin etc are already wrapped) or it gets GC:ed and weird things happen, see the ljsyscall project
-- it's really _G.spook by the way, eg. it's a global object
spook\on_read stdin, (reader, fd) ->
  data = fd\read!
  print "Got some data: #{data}"
```

### Coroutines

Spook, since release 0.8.0, wraps all event handlers in coroutines. This means that it is quite easy to use the asynchrony in a serial fashion rather than in a callback fashion. I don't believe this is especially relevant to the original use case of spook (eg. as a test feedback loop). However, since I've been using spook in other ways too I've found that a coroutine based flow can be quite helpful.

So, here's a brief example of Spook without and Spook with coroutines, first without:

```moonscript
every 1.0, (t) ->
  print "1 sec passed again"

every 5.0, (t) ->
  _, _, status = os.execute "sleep 2"
  print "sleep status: #{status}"
```

Above, the function given to every will have been wrapped in a coroutine. However, since nothing in that function actually yields (coroutine.yield) or resumes (coroutine.resume), it will just work the way spook always did - in the above case it will even "freeze" spook completely for 2 seconds waiting for sleep to exit (second every function). So the first every function that should execute once per second will skip a second.

There is a process helper that has, among other things, an os.execute api compatible implementation that is coroutine based. Using that to implement the same code as above would look like this:

```moonscript
:execute = require 'process'

every 1.0, (t) ->
  print "1 sec passed again"

every 5.0, (t) ->
  _, _, status = execute "sleep 2"
  print "sleep status: #{status}"
```

There's not much difference but you will see that there is no pausing of the 1 sec timer. This is a trivial example of course. For more interesting examples, see [moonbar](https://github.com/johnae/moonbar).

While you certainly CAN use os.execute as mentioned, I would recommend that you use the execute that comes with spook instead for job control (regardless of whether you care about coroutines). Like this:

```moonscript
execute = require('process').execute
every 5.0, (t) ->
  _, _, status = execute "sleep 2"
  print "sleep status: #{status}"
```

or, if you're using third party stuff, you might consider doing this (spooks own Spookfile does actually):

```moonscript
execute = require('process').execute
os.execute = execute
every 5.0, (t) ->
  _, _, status = os.execute "sleep 2"
  print "sleep status: #{status}"
```

Obviously above it won't make much difference to override the default os.execute but with third party code or code you don't want to change it may be extremely handy.

*NOTE:* you should probably prefer using the execute that comes with spook rather than os.execute. If only for the ability to actually interrupt whatever spook is running using CTRL-C (another CTRL-C would kill spook itself). Unless you have some specific reason to use os.execute of course.

### Notifications

This is how a simple notifier might look (load it using notify.add):

```moonscript
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

As is mentioned further down, one place to put notifiers might be in $HOME/.spook/lib since that is already on the package.path. For example, different team members might agree that a good place to put the notifier could be in "$HOME/.spook/lib/notifier.moon". Everyone's notifier can be different but is still referred to by the same name. Or some code might be written where any and all notifiers under a certain directory get loaded. There's no restrictions really.

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

Or another example that I'm currently using on Linux (you'll have to tweak it slightly to use your own icons):

```moonscript
success_icon = "#{os.getenv('HOME')}/Pictures/icons/essential/success.svg"
fail_icon = "#{os.getenv('HOME')}/Pictures/icons/essential/error.svg"

notify_send = (success, project, msg) ->
  cmd = if success
    "notify-send -i #{success_icon} -a 'Spook' -u normal '#{project}: SUCCESS' '#{msg}'"
  else
    "notify-send -i #{fail_icon} -a 'Spook' -u critical '#{project}: FAIL' '#{msg}'"
  os.execute cmd

getcwd = _G.getcwd
round = math.round
project_name = ->
  cwd = getcwd!\split '/'
  cwd[#cwd]

time_calc = (start, finish) ->
  round finish - start, 3

{
  success: (msg, info) ->
    :start_at, success_at: end_at = info
    msg = "tests passed in #{time_calc(start_at, end_at)}s"
    notify_send true, project_name!\upper!, msg

  fail: (msg, info) ->
    :start_at, fail_at: end_at = info
    msg = "tests failed in #{time_calc(start_at, end_at)}s"
    notify_send false, project_name!\upper!, msg
}
```

### Extending Spook

There's a package.path pointing to $HOME/.spook/lib as well as PROJECT_DIR/.spook/lib which means you can put any extensions in there (written in MoonScript or Lua) and load them easily from your Spookfile. This means you could extend functionality in infinite ways. This is really just convenience since you could just as easily add your own package paths directly to the Spookfile. However, to me it seems $HOME/.spook is a reasonable place to put such things as well PROJECT_DIR/.spook.

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


### Entr functionality

As mentioned up top, spook (since version 0.8.1) has gained the basic functionality of [entr](http://entrproject.org/). Using it in this mode is as simple as:

```sh
find . -type f | spook echo file changed: {file}
```

Or

```sh
ls *.moon | spook echo file changed: {file}
```

Since all commands in this scenario are passed to /bin/sh, this is also possible:

```sh
ls *.moon | spook "echo file changed: {file} && echo something else"
```

Perhaps a more relevant example of that would be something like:

```sh
ag -l | spook "make test && make"
```

Basically if tests pass, run the build.

Or keeping a log of changes like so:

```sh
find . -type f | spook "echo \$(date): {file} >> /tmp/changelog.txt"
```

These are exactly the kinds of things entr was made to do in a very simple and unsurprising fashion.

That last {file} "thing" by the way is a replacement string which will actually contain the file that changed. Two other variants of that are [file] and &lt;file&gt;. There's also {filenoext} which will be the filename without extension (with the path), there's {basename} which is the filename without the path and finally {basenamenoext} which is the filename without path and extension.

Please note that the entr functionality hasn't been extensively tested and some features of entr are missing. So far I've implemented the basics only. If the somewhat more advanced features of entr are desired I'd suggest using spook with a Spookfile as originally intended since that gives you almost unlimited flexibility. Or use the real entr - it is a very useful tool.

Also, the "restart server on changes" should work, something like:

```sh
find . -type f -name "*.go" | spook -s go run server.go
```

The above would run the server until a file in the given list of files changed at which time spook would restart the server. Using the "-s" switch means that the given utility to run is started immediately, not after a change is detected.

There's also a oneshot option (can't be used with the -s option for obvious reasons), -o, which executes the given utility just once then exits when a watched file changes:

```sh
find . -type f -name "*.jpg" | spook -o convert {file} -50% {filenoext}.small.jpg
```

### Other features

As of spook 0.8.7, any child process running in response to a file system change will have access to the env vars SPOOK_CHANGE_ACTION and SPOOK_CHANGE_PATH. These would correspond to the change that triggered the run. If the detected change is a move, SPOOK_MOVED_FROM will also be set.


### License

Spook is released under the MIT license (see [LICENSE.md](LICENSE.md) for details).

### Contribute

Anything is welcome. Bug reports and pull requests most of all.

Use the [Github issue tracker](https://github.com/johnae/spook/issues) for bug reports please.
I can be reached directly at \<john at insane.se\> as well as through github.

### In closing

Anything you can do with LuaJIT (FFI for example) you can do with Spook. Either in the Spookfile or files that you require (like the notifier). MoonScript and Lua are really powerful and fun and, coupled with LuaJIT, they're ridiculously fast too compared to basically all other dynamic languages and runtimes. They're not used often enough in my opinion. You should really give them a try - they deserve it, regardless of whether you like Spook or not.
