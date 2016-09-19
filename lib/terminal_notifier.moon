colors = require 'ansicolors'
round = math.round
time_calc = (event) ->
  round event.ended_at - event.started_at, 3

{
  info: (msg, event) ->
    print colors("[ %{dim}#{msg}%{reset} ]")

  success: (msg, event) ->
    msg = colors("[ %{green}PASSED")
    print msg .. colors "%{white} in #{time_calc(event)} seconds%{reset} ]"
    print ''

  fail: (msg, event) ->
    msg = colors("[ %{red}FAILED")
    print msg .. colors "%{white} in #{time_calc(event)} seconds%{reset} ]"
    print ''
}
