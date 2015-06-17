### Spook

Spook is aiming to be a light weight replacement for [guard](https://github.com/guard/guard). Please note that this is very early and almost doesn't work. Don't use it right now basically.

Building it should be as straightforward as:

```
make
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
    table.remove(elems, 1)
    table.remove(elems, 1)
    name = file\split(".")[1]
    path = table.concat(elems, "/")
    "spec/#{path}/#{name}_spec.moon"

  print "mapped to: #{file}"
  file
```
