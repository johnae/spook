moonscript = require "moonscript"
log = require("log")(0)
->
  config = {}
  cenv = {

    watch: (w) ->
      config.watch = require("dir_list")(w)

    map: (m) ->
      config.mapper = require("file_mapper")(m)

    log_level: (l) ->
      levels = {ERR: 0, WARN: 1, INFO: 2, DEBUG: 3}
      log_level = assert tonumber(l) or levels[l]
      config.log = require("log")(log_level)

    notifier: (n) ->
      local notifier
      config.notifier = if type(n) == "table"
        n
      else if type(n) == "string"
        status, notifier = pcall(-> return moonscript.loadfile(n)!)
        if not status
          log.debug "Failed to load notifier from #{n}: #{notifier}"
          notifier = require "default_notifier"
        notifier
      else
        require "default_notifier"

    command: (c) ->
      config.command = c

    show_command: (s) ->
      config.show_command = s

  }

  cenv = setmetatable cenv, __index: _G

  default_configuration = ->
    watch {"lib", "spec"}
    map {
      {"^lib/(.*)%.(.*)": (n, ext) -> "spec/#{n}.#{ext}"}
    }
    log_level "INFO"
    notifier require("default_notifier")
    command "ls"
    show_command false

  args_configuration = (args) ->
    watch args.watch unless args.watch == nil
    log_level args.log_level unless args.log_level == nil
    notifier args.notifier unless args.notifier == nil
    command args.command unless args.command == nil
    show_command args.show_command unless args.show_command == nil


  setfenv default_configuration, cenv
  setfenv args_configuration, cenv

  default_configuration!

  (opts={}) ->
    {:config_file, :args} = opts

    spook_configuration = if config_file
      assert moonscript.loadfile(config_file), "Failed to load #{config_file}"

    if spook_configuration
      setfenv spook_configuration, cenv
      spook_configuration!

    if args
      args_configuration args

    config

