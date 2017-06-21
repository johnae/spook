:red = require 'colors'

tobyte = (letter) ->
  byte = letter
  if type(letter) == 'string'
    byte = letter\byte!
  byte


keymapping_mt = {
  __index: {
    mapkey: (letter, func) =>
      byte = tobyte letter
      @[byte] = func
    keymap: (letter) =>
      byte = tobyte letter
      @[byte]
  }
}

new_keymap = ->
  map = {}
  setmetatable map, keymapping_mt
  map

new_cmd = (name, help, func) =>
  @[name] = {func, help}

dynamic = (func) =>
  @.__dynamic = {func, 'no help'}

cmdline_mt = {
  __index: (key, value) =>
    return new_cmd if key == 'cmd'
    return dynamic if key == 'dynamic'
    handler = rawget @, '__dynamic'
    if handler
      resolved = handler[1] @, key, value
      return {resolved} if resolved
    print red "Unknown command"
    @help
}

new_cmdline = ->
  cmdline = {}
  setmetatable cmdline, cmdline_mt
  cmdline

:new_cmdline, :new_keymap, :tobyte
