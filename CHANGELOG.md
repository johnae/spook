# Changelog

## 0.5.0

There are a couple of breaking changes in this one. See below for how to get
past them.

- Notifiers are now expected to live in ~/.spook/notifiers
  The recommendation is to first run "spook --setup", then to
  move your notifiers to ~/.spook/notifiers and then change your Spookfile
  to point to this new location. "spook --setup" also adds the default
  notifier to this directory - that is a useful notifier since it provides
  terminal output - something you probably always want.
- Notifiers can be loaded from a directory (specified in Spookfile)
- Notifiers CAN now provide a "runs" function which is expected to return true or false
  true means the notifier will run on the current system, false means it won't
- Notifiers now receive a table with relevant info instead of several arguments (breaks current notifiers)
  "start" will receive a table with the keys description and detail. description, for commands, contains the full
  command line while detail has just the file that's run.
  "finish" will receive two arguments - success and info. Here, info contains the additional key .elapsed_time.

### Other changes

- A CHANGEFILE.md has been added to the repo.
  
