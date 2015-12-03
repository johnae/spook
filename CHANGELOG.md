# Changelog

## 0.5.0

There are a couple of breaking changes in this one. See below for how to get
past them.

- Notifiers can be loaded from a directory (specified in Spookfile)
- Notifiers are now recommended to live in ~/.spook/notifiers
  The recommendation is to first run "spook --setup", then to
  move your notifiers to ~/.spook/notifiers and then change your Spookfile
  to point to this new location. "spook --setup" also adds the default
  notifier to this directory - that is a useful notifier since it provides
  terminal output - something you probably always want.
- Notifiers CAN now provide a "runs" function which is expected to return true or false
  true means the notifier will run on the current system, false means it won't.
  This is so it's easier to sync a directory full of notifiers between machines or
  environments of different types without changing Spookfiles.
- Notifiers now receive a table with relevant info instead of several arguments (breaks current notifiers)
  "start" will receive a table with the keys description and detail. description, for commands, contains the full
  command line while detail has just the file that's run.
  "finish" will receive two arguments - success and info. Here, info contains the additional key .elapsed_time.

### Breaking changes

The fact that notifier.start now receives a table and notifier.finish receives success and a table. The tables
contain the relevant information now.

The fact that there is no longer a built-in terminal notifier. This is a breaking change because you probably want
the terminal output. Instead you're expected to run "spook --setup" which creates ~/.spook/notifiers/terminal_notifier.moon,
that will enable the terminal notifications again. You must also add "notifier #{os.getenv('HOME')}/.spook/notifiers" to
your Spookfile for it to load (you can have multiple such definitions if you want notifiers to load from some other place
as well).

### Other changes

- A CHANGEFILE.md has been added to the repo.
  
