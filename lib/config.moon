->
  moonscript = require "moonscript"
  log = _G.log
  {:command, :func} = require "runners"
  {:remove} = table
  {:is_dir, :is_file, :dirtree} = require "fs"

  config = {watch: {}, notifiers: {}}
  loaded_notifiers = {}

  -- config env functions
  log_level = (l) ->
    config.log_level = tonumber(l) or log[l]

  notifier = (n) ->
    {:notifiers} = config
    t = type n
    if t == 'table'
      notifiers[#notifiers + 1] = n
      return
    assert t == 'string', 'A notifier must be a table (of functions) or a string (a path)'
    to_load = {}
    if is_dir n
      for entry, attr in dirtree n, true
        if entry\match "[^.].moon$"
          to_load[#to_load + 1] = entry
    else
      to_load = {n}

    for n in *to_load
      continue if loaded_notifiers[n]
      status, notifier = pcall -> moonscript.loadfile(n)!
      loaded_notifiers[n] = true
      unless status
        log.debug "Failed to load notifier from #{n}: #{notifier}, skipping"
        continue
      unless notifier.start or notifier.finish
        log.debug "Notifier #{n} doesn't implement the start and/or finish functions, skipping"
      if notifier.runs
        unless notifier.runs!
          log.debug "Notifier #{n} cannot run on this system, skipping"
          continue
      else
        log.debug "Notifier #{n} has no boolean 'runs' function, defaulting to true"
        log.debug "if this notifier can't run on all systems a 'runs' function should"
        log.debug "be added returning a bool where true means it can run on the system"

      notifiers[#notifiers + 1] = notifier

  watch = (...) ->
    args = {...}
    watch = remove args, #args
    change_handlers = {}
    on_changed = (matcher, runner) ->
      change_handlers[#change_handlers + 1] = {matcher, runner}

    watch_env =
      :command
      :func
      :on_changed

    setmetatable watch_env, __index: _G
    setfenv watch, watch_env
    watch!
    for dir in *args
      config.watch[dir] = change_handlers

  config_env =
    :log_level
    :command
    :func
    :notifier
    :watch

  setmetatable config_env, __index: _G

  default_configuration = ->
    log_level "INFO"

  args_configuration = (args) ->
    log_level args.log_level unless args.log_level == nil
    notifier args.notifier unless args.notifier == nil

  setfenv default_configuration, config_env
  setfenv args_configuration, config_env

  default_configuration!

  (opts={}) ->
    :config_file, :args = opts

    if config_file
      spook_configuration = assert moonscript.loadfile(config_file), "Failed to load #{config_file}"
      setfenv spook_configuration, config_env
      spook_configuration!

    if args
      args_configuration args

    config
