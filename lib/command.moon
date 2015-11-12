colors = require "ansicolors"
{:is_present} = require "fs"
{:round} = math

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

    notify.start cmdline, rest
    ts = gettimeofday! / 1000.0
    _, _, status = os.execute cmdline
    te = gettimeofday! / 1000.0
    elapsed = round te-ts, 3
    success = (status == 0)
    notify.finish success, cmdline, rest, elapsed
