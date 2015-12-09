colors = require "ansicolors"
{:is_present} = require "fs"

expand_file = (data, file) ->
  return nil unless data
  data\gsub '([[{%<](file)[]}>])', file

(cmd, opts={}) ->
  spook = opts.spook or _G.spook
  only_if = opts.only_if or is_present
  log = _G.log
  setmetatable {
    :cmd
  }, __call: (t, rest) ->

    cmdline, replaced = expand_file t.cmd, rest
    if replaced == 0
      cmdline = "#{t.cmd} #{rest}"

    unless only_if rest
      log.debug "Skipping run of '#{cmdline}' since only_if returned false"
      log.debug "  the default behavior is to not run when file (#{t.rest}) is missing"
      return

    run = ->
      _, _, status = os.execute cmdline
      status == 0

    spook.start description: cmdline, detail: rest, run
