colors = require 'ansicolors'

start = (what, data) ->
  print colors("[ %{dim}RUNNING #{what}%{reset} ]")

finish = (success, what, data, elapsed_time) ->
  msg = success and colors("[ %{green}PASSED") or colors("[ %{red}FAILED")
  print msg .. colors "%{white} in #{elapsed_time} seconds%{reset} ]"
  print ''

:start, :finish
