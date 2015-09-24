colors = require "ansicolors"
log = require("log")(2)

(cmd, opts={}) ->
  setmetatable {
    :cmd
  }, __call: (t, rest) ->
    if opts.show_command
      log.info colors("%{blue}[RUNNING] #{t.cmd} #{rest}")
    _, _, status = os.execute "#{t.cmd} #{rest}"
    status == 0 or false
