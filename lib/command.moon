colors = require "ansicolors"
{:is_present} = require "fs"

expand_file = (data, file) ->
  return nil unless data
  data\gsub '([[{%<](file)[]}>])', file

(cmd, opts={}) ->
  notify = opts.notify or _G.notify
  log = _G.log
  is_present = opts.only_if or is_present
  setmetatable {
    :cmd
  }, __call: (t, rest) ->

    cmdline, replaced = expand_file t.cmd, rest
    if replaced == 0
      cmdline = "#{t.cmd} #{rest}"

    unless is_present rest
      return log.debug "skipping '#{cmdline}' since #{rest} does not exist"

    run = ->
      _, _, status = os.execute cmdline
      status == 0

    notify.begin description: cmdline, detail: rest, run
