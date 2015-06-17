### Spook

Spook is aiming to be a light weight replacement for [guard](https://github.com/guard/guard). Please note that this is very early and may not work.

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
.spook
```

Eg. a hidden file. This file should be written as [moonscript](https://github.com/leafo/moonscript) and return a function that takes the input file as an argument, eg:

```moonscript
(changed_file) ->
   changed_file
```

The above just returns the file it was given but obviously there's alot of flexibility there. You might, in some cases, return an empty string which would normally result in running the full spec suite (if your tools are sane).

A more functional example of mapping (via the .spook file) might be:

```moonscript
{:P, :C, :Ct, :match} = require "lpeg"

string.split = (str, sep) ->
  sep = P(sep)
  elem = C((1-sep)^0)
  p = Ct(elem * (sep * elem)^0)
  match(p,str)

(changed_file) ->
  file = if changed_file\match '.*%_spec%..*$'
    changed_file
  else
    elems = changed_file\split("/")
    file = table.remove(elems)
    filename = file\split(".")[1]
    elems = [item for i, item in ipairs(elems) when i > 2]
    path = table.concat(elems, "/")
    "spec/#{path}/#{filename}_spec.moon"

  print "mapped to: #{file}"
  file
```

## Notifications

Notifications are very simple right now. The basics would be to create a file called .spook-notifier in your application directory. It should be
written in moonscript and is expected to return a function taking one argument - the exit status. Something like this:

```moonscript
(status) ->
  if status == 0
    print "All tests passed"
  else
    print "Tests failed"
```

A more complex notification example for tmux might look like this:

```moonscript
{:P, :C, :Ct, :match} = require "lpeg"

uv = require "uv"

ffi = require "ffi"
ffi.cdef [[
char *getcwd(char *buf, size_t size);
]]

string.split = (str, sep) ->
  sep = P(sep)
  elem = C((1-sep)^0)
  p = Ct(elem * (sep * elem)^0)
  match(p,str)

getcwd = ->
   buf = ffi.new("char[?]", 1024)
   ffi.C.getcwd(buf, 1024)
   ffi.string(buf)

project = ->
   cwd = getcwd!\split("/")
   cwd[#cwd]

tmux_set_status = (status) ->
  os.execute "tmux set status-right '#{status}' > /dev/null"

tmux_default_status = '#[fg=colour254,bg=colour234,nobold] #[fg=colour16,bg=colour254,bold] #(~/.tmux-mem-cpu-load.sh 2 0)'
tmux_fail_status = '#[fg=colour254,bg=colour234,nobold] #[fg=colour16,bg=colour254,bold] #(~/.tmux-mem-cpu-load.sh 2 0) | #[fg=white,bg=red] FAIL: ' .. project!
tmux_pass_status = '#[fg=colour254,bg=colour234,nobold] #[fg=colour16,bg=colour254,bold] #(~/.tmux-mem-cpu-load.sh 2 0) | #[fg=white,bg=green] PASS: ' .. project!

(status) ->
  if status == 0
    tmux_set_status(tmux_pass_status)
  else
    tmux_set_status(tmux_fail_status)

  uv.update_time!
  timer = uv.new_timer!
  timer\start 5000, 0, ->
    tmux_set_status(tmux_default_status)
    timer\close!
```
