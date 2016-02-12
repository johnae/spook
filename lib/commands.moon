(cmds) ->
  runs = {}
  local info
  for cmd in *cmds
    info, run = cmd!
    runs[#runs + 1] = run

  return info, ->
    success = true
    for run in *runs
      success and= run!
      return false unless success
    success
