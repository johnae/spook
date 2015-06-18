[![Build Status](https://travis-ci.org/johnae/spook.svg)](https://travis-ci.org/johnae/spook)

### Spook

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

After that you should have an executable called spook. It's known to build on Linux and Mac OS X.

## Running it

To watch directories you need to provide them on stdin like so:

```
find lib spec -type d | spook
```

To also run a utility (eg. rspec or some other test runner) you provide that via command line arguments, all together:

```
find lib spec -type d | spook bundle exec rspec
```

## Mapping files to other files

Normally you'd want a code change to map to some test file. To map files with spook you would create a file in the directory of your application called:

```
Spookfile
```

This file should be written as [moonscript](https://github.com/leafo/moonscript) and return a mapping table:

```moonscript
"(.*)": (m) -> m
```

The above just returns the file it was given but obviously there's alot of flexibility there. You might, in some cases, return an empty string which would normally result in running the full spec suite (if your tools are sane).

A more functional example of mapping via the .spook file (a rails app) might be:

```moonscript
"^(spec)/(spec_helper%.rb)": (a,b) -> "spec"
"^spec/(.*)/(.*)%.rb": (a,b) -> "spec/#{a}/#{b}.rb"
"^lib/(.*)/(.*)%.rb": (a,b) -> "spec/lib/#{a}/#{b}_spec.rb"
"^app/(.*)/(.*)%.rb": (a,b) -> "spec/#{a}/#{b}_spec.rb"
```

## Notifications

If you create a directory called .spook in your home dir and put a file called notifier.moon in there it will be loaded
and called by spook when certain events take place. Today the only events supported are "start" and "finish".
Something like this:

```moonscript
start = (changed_file) ->
  print "Running specs for file: #{changed_file}"

finish = (status) ->
  if status == 0
    print "Tests passed"
  else
    print "Tests failed"

:start, :finish
```

You must currently define both of the above functions and export them or things will crash and burn (you CAN skip creating the notifier completely though).

A more complex notification example for tmux might look like this:

```moonscript
uv = require "uv"

tmux_set_status = (status) ->
  os.execute "tmux set status-right '#{status}' > /dev/null"

tmux_default_status = '#[fg=colour254,bg=colour234,nobold] #[fg=colour16,bg=colour254,bold] #(~/.tmux-mem-cpu-load.sh 2 0)'
tmux_fail_status = '#[fg=colour254,bg=colour234,nobold] #[fg=colour16,bg=colour254,bold] #(~/.tmux-mem-cpu-load.sh 2 0) | #[fg=white,bg=red] FAIL: ' .. project_name!
tmux_pass_status = '#[fg=colour254,bg=colour234,nobold] #[fg=colour16,bg=colour254,bold] #(~/.tmux-mem-cpu-load.sh 2 0) | #[fg=white,bg=green] PASS: ' .. project_name!
tmux_test_status = '#[fg=colour254,bg=colour234,nobold] #[fg=colour16,bg=colour254,bold] #(~/.tmux-mem-cpu-load.sh 2 0) | #[fg=white,bg=cyan] TEST: ' .. project_name!

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
    tmux_set_status(tmux_default_status)
    stop_timer!

start = (changed_file) ->
  tmux_set_status tmux_test_status
  start_reset_timer!

finish = (status) ->
  if status == 0
    tmux_set_status(tmux_pass_status)
  else
    tmux_set_status(tmux_fail_status)

  start_reset_timer!

:start, :finish
```

Anything you can do with LuaJIT (FFI for example) you can do in the notifier so go crazy if you want to.

### Available addition functions in the global scope

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
