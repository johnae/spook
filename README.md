[![Build Status](https://travis-ci.org/johnae/spook.svg)](https://travis-ci.org/johnae/spook)

## Spook

Spook is aiming to be a light weight replacement for [guard](https://github.com/guard/guard). Please note that this is very early and may not work.
It is mostly written in [Lua](http://www.lua.org) and [moonscript](https://github.com/leafo/moonscript) with a sprinkle of C. It's built as a static
binary with no dependencies. The ridiculously fast [LuaJIT VM](http://luajit.org/) is embedded and compiled with Lua 5.2 compatibility. All extensions
and such should be written in [moonscript](https://github.com/leafo/moonscript).

You can download releases from [spook/releases](https://github.com/johnae/spook/releases). Currently only available for Linux x86_64 and Mac OS X x86_64.

Building it should be as straightforward as:

```
make
```

Installation is as straightforward as:

```
PREFIX=/usr/local make install
```

After that you should have an executable called spook. It's known to build on Linux and Mac OS X. Everything in the lib directory and toplevel is part of spook
itself, anything in vendor and deps is other peoples work and is just included in the resulting executable.

### Running it

To watch directories you need to provide them on stdin like so:

```
find lib spec -type d | spook
```

So basically you're telling spook to watch all files (recursively) in lib and spec. This will be done using whatever method
your OS provides courtesy of libuv.


To also run a utility (eg. rspec or some other test runner) you provide that via command line arguments, all together:

```
find lib spec -type d | spook bundle exec rspec
```

Actually you must provide a utility today. And, there's not much point in watching for changes without doing anything I suppose.

### Mapping files to other files via the Spookfile

Normally you'd want a code change to map to some test file. To map files with spook you would create a file in the directory of your application called:

```
Spookfile
```

This file should be written as [moonscript](https://github.com/leafo/moonscript) and return a mapping table where the keys are matchers (in Luas regex syntax)
and the values are functions taking the output of the matcher and (probably) transforming it somehow - the functions are only executed if there is an actual match:

```moonscript
{
  "(.*)": (m) -> m
}
```

The above just returns the file it was given but obviously there's alot of flexibility there. You might, in some cases, return an empty string which would normally result in running the full spec suite (if your tools are sane).

A more functional example of mapping via the Spookfile (for a rails app in this case) might be:

```moonscript
{
  "^(spec)/(spec_helper%.rb)": (a,b) -> "spec"
  "^spec/(.*)/(.*)%.rb": (a,b) -> "spec/#{a}/#{b}.rb"
  "^lib/(.*)/(.*)%.rb": (a,b) -> "spec/lib/#{a}/#{b}_spec.rb"
  "^app/(.*)/(.*)%.rb": (a,b) -> "spec/#{a}/#{b}_spec.rb"
}
```

### Notifications

If you create a directory called .spook in your home dir and put a file called notifier.moon in there it will be loaded
and called by spook when certain events take place. Today the only events supported are "start" and "finish".
Something like this in ~/.spook/notifier.moon:

```moonscript
start = (changed_file, mapped_file) ->
  print "#{project_name!}: running specs #{mapped_file} for changes in #{changed_file}"

finish = (status, changed_file, mapped_file) ->
  if status == 0
    print "#{project_name!}: tests in #{mapped_file} for changes in #{changed_file} passed"
  else
    print "#{project_name!}: tests in #{mapped_file} for changes in #{changed_file} failed"

:start, :finish
```

You must currently define both of the above functions and export them or things will crash and burn (you CAN skip creating the notifier completely though).

A more complex notification example for tmux might look like this (the uv package comes built in):

```moonscript
uv = require "uv"

tmux_set_status = (status) ->
  os.execute "tmux set status-right '#{status}' > /dev/null"

tmux_default_status = '#[fg=colour254,bg=colour234,nobold] #[fg=colour16,bg=colour254,bold] #(~/.tmux-mem-cpu-load.sh 2 0)'
tmux_fail_status = tmux_default_status .. ' | #[fg=white,bg=red] FAIL: ' .. project_name!
tmux_pass_status = tmux_default_status .. ' | #[fg=white,bg=green] PASS: ' .. project_name!
tmux_test_status = tmux_default_status .. ' | #[fg=white,bg=cyan] TEST: ' .. project_name!

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

finish = (status, changed_file, mapped_file) ->
  if status == 0
    tmux_set_status tmux_pass_status
  else
    tmux_set_status tmux_fail_status

  start_reset_timer!

:start, :finish
```

There's a gist for the above I just clone to ~/.spook here: [tmux notifier gist](https://gist.github.com/johnae/fc8e04acef49999fc5c9)

Anything you can do with LuaJIT (FFI for example) you can do in the notifier so go crazy if you want to.


### Available additional functions in the global scope

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
