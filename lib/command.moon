colors = require "ansicolors"
{:is_present} = require "fs"
{:round} = math

(cmd, opts={}) ->
  notify = opts.notify or _G.notify
  log = _G.log
  is_present = opts.only_if or is_present
  setmetatable {
    :cmd
  }, __call: (t, rest) ->
    unless is_present rest
      return log.debug "skipping '#{t.cmd} #{rest}' since #{rest} does not exist"
    notify.start t.cmd, rest
    ts = gettimeofday! / 1000.0
    _, _, status = os.execute "#{t.cmd} #{rest}"
    te = gettimeofday! / 1000.0
    elapsed = round te-ts, 3
    success = (status == 0)
    notify.finish success, t.cmd, rest, elapsed
