moonscript = require "moonscript"
log = require("log")(0)
->

  config = {watch: {}}
  config_env = {

    show_command: (s) ->
      config.show_command = s

    log_level: (l) ->
      levels = {ERR: 0, WARN: 1, INFO: 2, DEBUG: 3}
      config.log_level = assert tonumber(l) or levels[l]

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

    watch: (...) ->
      args = {...}
      f = table.remove args, #args
      local command
      tmap = {}
      conf = {}
      watch_env = {
        map: (m, r) ->
          tmap[#tmap + 1] = {m, r}

        command: (c) ->
          command = c
      }
      setmetatable watch_env, __index: _G
      setfenv f, watch_env
      f!
      for dir in *args
        config.watch[dir] = {:command, map: tmap}

  }

  setmetatable config_env, __index: _G

  default_configuration = ->
    watch "lib", "spec", ->
      map "^lib/(.*)%.(.*)", (n, ext) -> "spec/#{n}.#{ext}"
      command "ls"
    log_level "INFO"
    notifier require("default_notifier")
    show_command false

  args_configuration = (args) ->
    unless args.watch == nil
      watch unpack(args.watch), ->
        command args.command unless args.command == nil

    log_level args.log_level unless args.log_level == nil
    notifier args.notifier unless args.notifier == nil
    show_command args.show_command unless args.show_command == nil


  setfenv default_configuration, config_env
  setfenv args_configuration, config_env

  default_configuration!

  (opts={}) ->
    {:config_file, :args} = opts

    spook_configuration = if config_file
      assert moonscript.loadfile(config_file), "Failed to load #{config_file}"

    if spook_configuration
      setfenv spook_configuration, config_env
      spook_configuration!

    if args
      args_configuration args

    config

