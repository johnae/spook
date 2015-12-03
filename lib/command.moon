colors = require "ansicolors"

expand_file = (data, file) ->
  return nil unless data
  data\gsub '([[{%<](file)[]}>])', file

(cmd, opts={}) ->
  notify = opts.notify or _G.notify
  log = _G.log
  setmetatable {
    :cmd
  }, __call: (t, rest) ->

    cmdline, replaced = expand_file t.cmd, rest
    if replaced == 0
      cmdline = "#{t.cmd} #{rest}"

    run = ->
      _, _, status = os.execute cmdline
      status == 0

    notify.begin description: cmdline, detail: rest, run
