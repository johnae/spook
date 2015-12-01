->
  moonscript = require "moonscript"
  log = _G.log
  command = require "command"
  {:remove, :insert} = table
  {:is_dir, :is_file, :dirtree} = require "fs"

  config = {watch: {}, notifiers: {}}
  config_env = {

    log_level: (l) ->
      config.log_level = assert tonumber(l) or log[l]

    :command

    notifier: (n) ->
      notifiers = config.notifiers
      if type(n) == "table"
        notifiers[#notifiers + 1] = n
      else if type(n) == "string"
        to_load = {}
        if is_dir n
          for entry, attr in dirtree n
            if entry\match "[^.].moon$"
              to_load[#to_load + 1] = entry
        else
          to_load = {n}

        for n in *to_load
          status, notifier = pcall(-> return moonscript.loadfile(n)!)
          unless status
            log.debug "Failed to load notifier from #{n}: #{notifier}, skipping"
            continue
          unless notifier.start or notifier.finish
            log.debug "Notifier #{n} doesn't implement the start and/or finish functions, skipping"
            continue
          if notifier.runs
            unless notifier.runs!
              log.debug "Notifier #{n} cannot run on this system, skipping"
              continue
          else
            log.debug "Notifier #{n} has no boolean 'runs' function, defaulting to true"
            log.debug "if this notifier can't run on all systems a 'runs' function should"
            log.debug "be added returning a bool where true means it can run on the system"

          notifiers[#notifiers + 1] = notifier

    watch: (...) ->
      args = {...}
      f = remove args, #args
      tmap = {}
      watch_env = {
        :command

        on_changed: (m, r) ->
          tmap[#tmap + 1] = {m, r}

      }
      setmetatable watch_env, __index: _G
      setfenv f, watch_env
      f!
      for dir in *args
        config.watch[dir] = tmap

  }

  setmetatable config_env, __index: _G

  default_configuration = ->
    change_handler = (s) ->
      print "Mapped file #{s}"
    watch "lib", "spec", ->
      on_changed "^lib/(.*)%.(.*)", (n, ext) -> change_handler "spec/#{n}.#{ext}"
    log_level "INFO"

  args_configuration = (args) ->
    log_level args.log_level unless args.log_level == nil
    notifer args.notifier unless args.notifier == nil

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

