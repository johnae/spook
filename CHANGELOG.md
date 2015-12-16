# Changelog

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

Again, this change may not be used by anyone currently.


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
  
