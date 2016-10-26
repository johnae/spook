# Changelog

## 0.7.0

This has several breaking changes but also new features. The reason for all this is the removal of libuv and luv and the wish to implement many more features. The rationale for removing libuv/luv is to enable a finer grained fs events infrastructure. No longer is the only handler "on_changed". There's now also "on_deleted", "on_created", "on_moved", "on_modified" and "on_attrib". In addition to those, signals and timers with associated handlers can be directly defined as part of the Spookfile (or somewhere else by reaching for the global "spook" object which has the necessary functions on it).

The "on_changed" handler has been changed so that it does NOT catch delete events at all. It does catch all the others however.
For delete events, use "on_delete". For catching only specific events - don't use "on_changed" but rather "on_modified", "on_moved" etc.

Windows support, which was theoretically possible previously through libuv/luv, is now much less likely (though not impossible since there are ffi bindings for the windows api:s). I don't use Windows myself and know of noone who has even tried using spook on that platform.

All the watch handlers (eg. on_changed etc) receives the event as its first argument, the rest being the matches. So, always expect the event as the first argument. Eg.

```moonscript
on_changed '^some/dir/#{name}.moon', (event, name) ->
  ...
```

As of now, this only supports Linux. I plan to support the BSD:s (including OS X) at some point. The BSD:s especially lack a fully featured fs watcher implementation. Sockets, timers etc. should all work on BSD:s. You're welcome to help out with this.

Since spook is now meant as a more comprehensive and therefore less specific solution, some things have been rearchitected and many removed. I still use spook as a test-runner a la rspec so it's still really a main use case. I plan on rewriting my (hacky as hell) i3bar thing [Eye3](https://github.com/johnae/eye3) to use spook now instead since that should be absolutely possible (and was something I wanted to make possible with this version of spook).

## 0.6.0

There is a breaking change for function handlers. Probably not used by anyone. See below for more. Another
possible breaking change for anyone who relied on the content of the info table sent to notifier.start/finish.

- multiple commands per change handler can be specified by adding them together
- added linting as part of CI (and to Spookfile)
- changed how function handlers and command handlers work wrt notifiers
- the content of the info table in an event has changed

Using multiple commands looks like this:

```
list_cmd = command "ls -lah"
build_cmd = command "build"
show_cmd = command "echo '[file]'"

watch "lib", ->
   on_changed "^lib/(.*)%.moon" (a) ->
     list_cmd("lib/#{a}.moon") +
     build_cmd("lib/#{a}.moon") +
     show_cmd("lib/#{a}.moon")
```

If a command fails the rest of the chain is aborted. The notifier.finish will receive a list of
all the handlers that were able to run + the one that failed which will be the last in that list.

Defining a function handler now works like this:

```
my_handler = func name: "my_handler", handler: (file) ->
   "do stuff to file"
   true -- or false, depending on success

watch "dir", ->
   on_changed "^path/to/(.*).moon", (a) -> my_handler "other/dir/#{a}_spec.moon"
```

Function handlers can be used together with command handlers like this:

```
my_handler = func name: "my_handler", handler: (file) ->
   "do stuff to file"
   true -- or false, depending on success

my_cmd = command "ls -lah"

watch "dir", ->
   on_changed "^path/to/(.*).moon", (a) ->
      my_handler "path/to/#{a}.moon" +
      my_cmd "spec/#{a}_spec.moon"
```

The info table sent to notifiers has changed somewhat. The start handler now receives a table like this:

```
{
  changed_file: "the file that was changed triggering this",
  mapped_file: "the file mapped from the changed file",
  name: "a short name of what is now running",
  args: "the arguments sent to what is now running",
  description: "a longer name for what is now running"
}
```

The info table sent to the finish handler has changed the most:

```
{
  1: {
    changed_file: "the file that was changed triggering this",
    mapped_file: "the file mapped from the changed file",
    name: "a short name of what is now running",
    args: "the arguments sent to what is now running",
    description: "a longer name for what is now running"
    success: true
  }
  changed_file: "the file that was changed triggering this",
  elapsed_time: 0.100,
  id: "sha256 id for this run"
}
```

So the finish handler event is both a k/v table and a list. The list
contains all the things that have run (eg. commands and/or functions)
and also contains the return values. If any command in the list fails
later commands will not run and the last command in the list will be the
one that failed.

See this repos [Spookfile](Spookfile) for some hints.


## 0.5.5

No new features in this one either. Just tweaks to the Makefile and test fixes on Mac OS X.

- make can now run parallelized correctly
- tests are (again) passing on OS X

## 0.5.4

No new features in this one. Just some updated dependencies.

- Update luv dependency to 1.8.0-1
- Switch luajit dependency to use github repo (travis is blocked from pulling from luajit.org)

## 0.5.3

- Updated argparse library to 0.5.0
- string.split was simplified and improved somewhat (no longer using lpeg)
- Added chdir function through ffi
- Added -w (--dir) switch for changing working directory (based on chdir)
- Updated built-in moonscript to 0.4.0
- Prefer moonscript versions of files when compiling spook (and then skip the lua ones)
- Tests were added for utility functions


## 0.5.2

- Fix a possible moonscript parsing issue on Darwin. Quite baffling. This fixes the "spook --setup" problem on Darwin.
- Cleans up the help output to not include deprecated usage anymore.


## 0.5.1

One breaking change that probably won't affect anyone (don't have many users atm). See below for a
list of the changes and more info on the one breaking change. Normally this might not really be ok in
a point release (I think) but since the project is so new, the feature is probably not used by anyone and
made the other changes easier to make I opted to do it anyway. Sorry if someone was actually affected - the
change needed in any such code is extremely small - see below for examples.

- Any custom handler functions (as opposed to commands) are now expected to return the info table + the
  function to run (as opposed to calling notify.begin with those parameters). This is the one breaking change.
  The return is a two value one where the first is the info table and the last is the function. This might not
  be used by anyone (yet) and I'm not using it atm even.
- The table received by notifier.start/finish now contains the changed file in the field "changed_file".
- Previous releases could exhibit stupid behavior when spook was running and, for example, you switched
  git branch (which in turn "changed" lots of files on disk). Spook could then end up in a situation where
  the same command and file were run several times. This has been resolved through a better design.
- There's now a package.path pointing to $HOME/.spook/lib as well as PROJECT_DIR/.spook/lib from where
  additional code (in moonscript or lua) may be loaded in your Spookfile. Assuming you put "my_util.moon"
  under $HOME/.spook/lib/stuff, you would load that like:

```moonscript
utils = require "stuff.my_util"
```

Any files under PROJECT_DIR/.spook/lib named the same as in $HOME/.spook/lib take precedence so the global
ones may be overridden that way.


On the breaking change:

  Custom handlers used to look like this:

```moonscript
handle = (file) ->
   "do stuff to file"
   true -- or false, depending on success

change_handler = (file) -> notify.begin description: "handle #{file}", detail: file, -> handle file

watch "dir", ->
   on_changed "^path/to/(.*).moon", (a) -> change_handler "other/dir/#{a}_spec.moon"
```

  But they're now expected to look like this:

```moonscript
handle = (file) ->
   "do stuff to file"
   true -- or false, depending on success

change_handler = (file) -> description: "handle #{file}", detail: file, -> handle file

watch "dir", ->
   on_changed "^path/to/(.*).moon", (a) -> change_handler "other/dir/#{a}_spec.moon"
```

Eg. they should return the info table and the function to handle the detected change.

Again, this feature might not be used by anyone currently.


## 0.5.0

There are a couple of breaking changes in this one. See below for how to get
past them.

- Notifiers can be loaded from a directory (specified in Spookfile)
- Notifiers are now recommended to live in ~/.spook/notifiers
  The recommendation is to first run "spook --setup", then to
  move your notifiers to ~/.spook/notifiers/some-directory and then change
  your Spookfile to point to ~/.spook/notifiers. "spook --setup" also adds the default
  notifier to a sub directory called "default" - that one is a useful notifier since it
  provides terminal output - something you probably always want.
- Notifiers CAN now provide a "runs" function which is expected to return true or false
  true means the notifier will run on the current system, false means it won't.
  This is so it's easier to sync a directory full of notifiers between machines or
  environments of different types without changing Spookfiles.
- Notifiers now receive a table with relevant info instead of several arguments (breaks current notifiers)
  "start" will receive a table with the keys description and detail. description, for commands, contains the full
  command line while detail has just the file that's run.
  "finish" will receive two arguments - success and info. Here, info contains the additional key .elapsed_time.
- There are no default watch dirs defined. These were previously always added to any existing configuration. It was
  a stupid thing really and could be seen as errors (usually) in debug mode.

### Breaking changes

The fact that notifier.start now receives a table and notifier.finish receives success and a table. The tables
contain the relevant information now.

Example info table for notifier.start(info):

```moonscript```
{
  description: "./bin/rspec -f d spec/my/awesome_spec.rb",
  detail: "spec/my/awesome_spec.rb"
}
```

Example info table for notifier.finish(sucess, info):

```moonscript```
{
  description: "./bin/rspec -f d spec/my/awesome_spec.rb",
  detail: "spec/my/awesome_spec.rb",
  elapsed_time: 8.347
}
```

The fact that there is no longer a built-in terminal notifier. This is a breaking change because you probably want
the terminal output. Instead you're expected to run "spook --setup" which creates ~/.spook/notifiers/default/terminal_notifier.moon,
that will enable the terminal notifications again. You must also add "notifier #{os.getenv('HOME')}/.spook/notifiers" to
your Spookfile for it to load (you can have multiple such definitions if you want notifiers to load from some other place
as well).

### Other changes

- A CHANGEFILE.md has been added to the repo.
