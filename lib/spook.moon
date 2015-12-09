(notify) ->
  runs = {}
  log = _G.log
  {
    clear: ->
      for ran, _ in pairs runs
        runs[ran] = nil

    start: (info, fn) ->
      info.id or= info.description
      if runs[info.id]
        log.debug "Skipping run for #{info.id} - last run too recent"
        return
      runs[info.id] = true
      notify.begin info, fn
  }
