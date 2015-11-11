colors = require "ansicolors"

(cmd, opts={}) ->
  setmetatable {
    :cmd
  }, __call: (t, rest) ->
    if opts.show_command
      print colors("[ %{dim}RUNNING #{t.cmd} #{rest} ]")
    _, _, status = os.execute "#{t.cmd} #{rest}"
    status == 0
