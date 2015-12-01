colors = require 'ansicolors'

runs = -> true

start = (info) ->
  print colors("[ %{dim}RUNNING #{info.description}%{reset} ]")

finish = (success, info) ->
  msg = success and colors("[ %{green}PASSED") or colors("[ %{red}FAILED")
  print msg .. colors "%{white} in #{info.elapsed_time} seconds%{reset} ]"
  print ''

:start, :finish, :runs
