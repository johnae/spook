# Changelog

## 0.9.1 - unreleased

Fixes around "entr" behavior (eg. reading the files to be watched on stdin). When there is a controlling terminal this behavior is
now completely skipped, otherwise there is a default timeout waiting for data on stdin (2 seconds). This timeout can be changed via
the commandline argument ```-r```. ```-r 0``` disables waiting for stdin completely.

There has been further performance improvements to the actual fs events behavior in "entr" mode.

An issue, under some preconditions, of adding several instances of the same directory to a watch has been solved.

When not given a command to run in entr mode, spook will now echo the changed file path on stdout rather than some debug string on stderr.

## 0.9.0

Simplifies the entr functionality. This means spook shouldn't choke on a dir such as $HOME (which likely
has alot of sub directories).

Make sure the logger doesn't cause problems when packing code. This is a fix to the build system.

Fix fs.dirtree when root is given. When / is given to fs.dirtree would erroneously remove the / and we
would be left with an empty string.

Update lint_config (avoids lint errors on Spookfile in this repo).

Updates ljsyscall to 3e482bc.

Updates luajit to v2.1 fe651bf.

Fixes travis build error on OS X.

## 0.8.9

*NOTE:* Please update to this version if you are on 0.8.7 or 0.8.8 since those have a bug randomly resulting in a segmentation fault.

Fix a segmentation fault occurring seemingly randomly. We cannot write nil to the value of an env var. So I would really recommend using this

Spook now gives a descriptive message when setting bad log level.

## 0.8.8

Correct the helptext on the -f option so it notes that BOTH MoonScript and Lua files are supported.

Spook now aborts if the inotify (so linux only) watch limit is reached rather than watching some of
the given files (well actually directories) without notifying the user.

The Queue thing was removed and replaced by a table. The queue wasn't actually needed.

A bit of code cleanup - make lint now lints init.moon as well.

Luajit now at https://github.com/LuaJIT/LuaJIT/commit/850f8c59d3d04a9847f21f32a6c36d8269b5b6b1 - LJ_GC64: Make ASMREF_L references 64 bit.

The chdir helper which takes a function now returns not only whether chdir was successful but also any return values of the given function. The function also receives the success status of the actual chdir execution - either true (successful) or nil (failed).

## 0.8.7

The env vars SPOOK_CHANGE_ACTION and SPOOK_CHANGE_PATH are now always set when a change is detected.
The use case is that any executed utility now has access to some basic information on what changed.
If the action was a move, the env var SPOOK_MOVED_FROM will also be set to the path where the file
used to be found.

Fix crashing bug on BSD when moving files around.

Some fixes and improvements to the integration tests and updates to the travis yml to use ubuntu Trusty.
This made the tmux-next both unnecessary and seemingly buggy - so a simplified travis yml without any reference
to some launchpad repo for a later tmux.

## 0.8.6

A bug in entr mode which could result in no action being taken has been fixed while at the same time simplifying some needlessly convoluted code.

spook -i should now generate a Spookfile that works (eg. not note.info but notify.info).

Command completion in REPL was improved.

Added an fs.dirname function.

## 0.8.5

Repl history is now persistent and is stored in $PWD/.spook_history.

Now generates Spookfiles that use reload_spook by default rather than load_spookfile, reload_spook re-executes spook which results
in a cleaner environment where everything really does reload.

An issue with keymapping in the repl has been fixed (escape sequence could result in trying to call a nil value).

## 0.8.4

### New feature

A repl has been added to spook (not when run in entr mode though). To use it, you would do something like this in the Spookfile:

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

### Fixes

Fixes a subtle bug (only manifested on FreeBSD) regarding file watches and entr mode.
Makes globals available in the on_changed handlers. Basically, previously if you did this:

```moonscript
watch "dir", ->
  on_changed "^dir/(.*)", (event, name) ->
    notify.info "Stuff happened to: #{name}"
```

That would fail because notify is a global and within the on_\* handlers of the watches, globals
weren't available. This has been fixed. (you'd have do make a local out of it somewhere in the Spookfile
before the change handler and refer to that local previously - this was quite surprising behavior).

Ctrl-c in quick succession will send the KILL signal to children (eg. if they're unresponsive).

string.split can now split on nothing, eg. the empty string.

It's now possible to peek at any element by index in a queue.

_Development related fixes_

Improved the integration test suite - tmux runs on a socket specific for the test run (eg. if you actually use tmux otherwise, that instance is not affected).
Updated the dev dependency moonpick to the latest version.

Also, binary builds have been disabled for now.


## 0.8.3

An environment (a Lua k/v table) can now be passed to the command factory function and to the instances it creates (keys in the env passed to the instances takes precedence over the same keys passed to the factory function).

A bug in the spookfile_helpers was fixed (apparently the spook version of execute was in fact NOT used when it should have been).

## 0.8.2

Using the latest LuaJIT 2.1 commit https://github.com/LuaJIT/LuaJIT/commit/b0ecc6dd65a0b40e1868f20719c4f7c4880dc32d as it solves some issues on FreeBSD regarding resource limits (FreeBSD >= 10).

Some minor cleanup. Job control was improved quite a bit. Actually, now children are put into their own groups and can be controlled individually. Previously they were put into the same group as Spook and that was plain wrong and sometimes lead to strange behavior.

Integration tests were added for the entr functionality but I'm hoping to use them for more than that at some point.

## 0.8.1

_NOTE_: you should really think about replacing calls to os.execute with:

```moonscript
execute = require('process').execute

success, etype, status = execute "somecommand"
```

This will give you job control (eg. you can ctrl-c and stop a running spec for example, then ctrl-c again to exit spook) among many other niceties.

Spook gained the basic functionality of the [entrproject](http://entrproject.org). Usage:

```sh
find . -type f | spook echo {file}
```

Other replacement strings are {filenoext}, {basename} and {basenamenoext}.

The -s option is for server type things (eg. restart server when code changes). This will start the utility (server) immediately and restart it (terminate first using SIGTERM) when files change.

The -o option can't be used with the -s option. It means oneshot and will just execute whatever utility given once when files change then exit.

No options (but data on stdin) means wait for changes, then execute utility - repeat.

Some minor fixes on \*BSD/OSX.

Fixed a subtle bug in single file watches (eg. watch_file). Basically if a dir in the path to a file was named the same as the file itself bad stuff would happen.

Spook should now properly handle children and signals by default. Previously, when trying to CTRL-C out of something, it wouldn't always do anything. Now spook should terminate all children on CTRL-C. If there are no children it will terminate itself (so CTRL-C twice exits completely when spook is running something).

As part of the entr functionality being added a general cleanup of job control was done and it should now behave much better overall. *To actually have this work, you must NOT use os.execute but rather something like ```execute = require('process').execute```*. The spookfile_helpers use the new execute behind the scenes.

A readlines function was added as a helper for reading lines (rather than just bytes) from stdin.

The fs module gained the name_ext function which returns the filename without extension and the extension as the second return value. Fs also gained the basename function which will return the basename of a filepath (eg. just the filename).

## 0.8.0

There are now real recurring timers. "after" is the timeout while "every" is the new recurring timer ("timer" has been kept for now and does the same as "after").

On Linux signalfd is now closed on exec and nonblocking as it should have been all along. On BSD the SIGCHLD signal is now NEVER blocked since that actually blocks it from being received on kqueue.

All event handlers are now wrapped in coroutines which enables using spook easily in that fashion. It can sometimes make for simpler code (eg. avoiding callbacks).

There are now process helpers (see lib/process.moon) that will help with fork/exec coupled with coroutines.

signalblock and signalunblock are now exported from the event sub systems since they are useful in the new process helpers.

Also there's a few fixes mainly for the BSD:s and in particular for FreeBSD. A few fixes and updates to the tooling. Building on FreeBSD now only requires gmake.

## 0.7.8

Updated ljsyscall to ee90324b07e5f64cbe1b91cae7b8396992fcc48d. Stopped linking librt. Instead of using the log to show info on how many directories/files are watched on spook start/restart, notify is used instead. That way it's possible to completely disable that output without messing with log levels (eg. simply not adding a notifier that notifies on info).


## 0.7.7

No new api functionality. Updated luajit to Luajit 2.1.0 beta3 which is now also built in GC64 mode. Moved from using the list[#list + 1] = something construct to just using table.insert consistently.

## 0.7.6

No new api functionality. There was a small addition to the queue implementation - it can now be reset (eg. emptied). Some more tests were added and spook was tested and confirmed working properly on FreeBSD. Still have to install gmake and link clang to gcc for it to work but other than that it seems fine.

## 0.7.5

Now all notifiers are cleared out when reloading Spookfile in place. Previously they would bunch up and you'd be in notify hell.
Behind the scenes a struct is used for the identification of kqueue vnode watches. This was previously a string. Makes for better organization and avoids situations where the path name may interfere with the used scheme.
On Linux epoll may return nil when system is suspended/woken up. The same workaround has been implemented in case kqueue can also return nil, it should now just advance to the next iteration.

## 0.7.4

Forgot to actually make this log part of the 0.7.4 tag. 0.7.4 merely makes the spookfile_helpers a built-in and makes a global out of notify. The reason for this is that it simplifies using spook as a spec runner since one doesn't need to store some file to require somewhere and possibly reimplement for every project. Making notify a global simplified it's use from spookfile_helpers in turn.

## 0.7.3

The main fix in this one is support for OS X (and the BSD:s). This took a while to get around to since I don't use OS X or BSD myself. Therefore, even though tested, I would much appreciate it if someone on a Mac tried it out to iron out any left over bugs.

Everything that worked on Linux previously should work the same on OS X / BSD. Possibly some slight differences in behavior for fs events but those should be minor and not relevant to most use cases I can think of.

## 0.7.2

A bugfix related to garbage collection. This also removes the "Stdin" reader - only "Read" is necessary. "Read" now requires a wrapped FD as input (like what ljsyscall returns). Without at wrapped FD, it would get garbage collected and all sorts of crazy things happened as a result.

The callback to "Read" will now get the FD rather than the data. This is to enable more control in the consuming function, but obviously it requires the user to actually issue a read on the FD (otherwise the event will be received again and again indefinitely).

The printing of how many directories/files are watched is done through the logger now rather than using just "print". When not using spook as a sort of "guard" replacement (eg. a test runner), it's not very convenient to have it dump stuff on stdout if what you wanted was to send specially formatted data on stdout.

The logger is now configurable and can be changed by setting the logger function like so:

```moonscript
log.logger (...) ->
  print ... -- or maybe write to file instead?
```

There's a trim function defined on string now.

A workaround is now present for "crashing when suspending/hibernating".

## 0.7.1

Minor changes in the notify api. Mostly, you can only add one notifier at a time eg. notify.add 'one_notifier' as opposed to notify.add 'one_notifier', 'two_notifier'. There is (for now) always a signal handler defined which can be replaced. This somewhat simplified the evented signal handling (and avoided problems when hot reloading).

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
