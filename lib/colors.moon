colors = {
  RESET: 0
  BRIGHT: 1
  DIM: 2
  UNDERLINE: 4
  BLINK: 5
  REVERSE: 7
  HIDDEN: 8

  -- foreground
  BLACK: 30
  RED: 31
  GREEN: 32
  YELLOW: 33
  BLUE: 34
  MAGENTA: 35
  CYAN: 36
  WHITE: 37

  -- background
  BLACK_BG: 40
  RED_BG: 41
  GREEN_BG: 42
  YELLOW_BG: 43
  BLUE_BG: 44
  MAGENTA_BG: 45
  CYAN_BG: 46
  WHITE_BG: 47
}

colorize = (color) ->
  (str) -> 
    return str unless color
    "\027[#{color}m#{str}\027[0m"

colors_mt = {
  __index: (t, key, val) ->
    colorize t[key\upper!]
}

setmetatable colors, colors_mt
colors
