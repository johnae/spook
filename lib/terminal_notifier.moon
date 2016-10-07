colors = require 'ansicolors'
round = math.round
time_calc = (start, finish) -> round finish - start, 3

{
  info: (msg, info) ->
    print colors("[ %{dim}#{msg}%{reset} ]")

  success: (msg, info) ->
    msg = colors("[ %{green}SUCCEEDED")
    :start_at, success_at: end_at = info
    print msg .. colors "%{white} in #{time_calc(start_at, end_at)} seconds%{reset} ]"
    print ''

  fail: (msg, info) ->
    msg = colors("[ %{red}FAILED")
    :start_at, fail_at: end_at = info
    print msg .. colors "%{white} in #{time_calc(start_at, end_at)} seconds%{reset} ]"
    print ''
}
