{:is_present} = require "fs"

expand_file = (data, file) ->
  return nil unless data
  data\gsub '([[{%<](file)[]}>])', file

(cmd, opts={}) ->
  only_if = opts.only_if or is_present
  log = _G.log
  setmetatable {
    :cmd
  }, __call: (t, file, o={}) ->

    cmdline, replaced = expand_file t.cmd, file
    if replaced == 0
      cmdline = "#{t.cmd} #{file}"

    unless only_if file
      log.debug "Skipping run of '#{cmdline}' since only_if returned false"
      log.debug "  the default behavior is to not run when file (#{file}) is missing"
      return

    allow_fail = opts.allow_fail or o.allow_fail or false

    return description: cmdline, detail: file, ->
      _, _, status = os.execute cmdline
      return true if allow_fail
      status == 0
