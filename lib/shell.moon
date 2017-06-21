S = require 'syscall'
:read, :is_callable = require 'utils'
:new_cmdline, :new_keymap, :tobyte = require 'shell_utils'
:red, :blue, :white = require 'colors'
parse = require 'moonscript.parse'
compile = require 'moonscript.compile'
:insert, :concat, :remove = table
:max = math
:getcwd = _G

history_mt = {
  __index: {
    reset_pos: => @pos = #@ + 1

    back: =>
      at = @pos - 1
      if at > 0
        @pos = at
        return @current!
      false

    forward: =>
      at = @pos + 1
      if at <= #@
        @pos = at
        return @current!
      false

    current: => @[@pos]

    add: (line) =>
      if line and #line > 0
        for i, l in ipairs @
          l1 = concat line, ''
          l2 = concat l, ''
          remove @, i if l1 == l2
        insert @, line
        @pos = #@ + 1
        @save!

    load: =>
      hpath = getcwd! .. '/.spook_history'
      file = io.open hpath, 'r'
      content = if file
        c = file\read '*a'
        file\close!
        c
      else
        ''
      lines = content\split '\n'
      for idx, line in ipairs lines
        -- only load last 1000 (and therefore never really save more than 1000)
        continue if (#line - idx) > 1000
        l = line\split ''
        @add l

    save: =>
      hpath = getcwd! .. '/.spook_history'
      file = io.open hpath, 'w'
      if file
        for line in *@
          file\write concat(line, '') .. '\n'
        file\close!
  }
}

new_history = ->
  history = {pos: 1}
  setmetatable history, history_mt
  history\load!
  history

(prompt) ->
  history = new_history!
  get_prompt = is_callable(prompt) and prompt or -> prompt

  enable_raw = (screen) ->
    fd = screen.rfd
    screen.old_termios or= assert fd\tcgetattr!
    unless screen.raw
      termios = assert fd\tcgetattr!
      termios\makeraw!
      assert fd\tcsetattr('FLUSH', termios)
      screen.raw = true

  disable_raw = (screen) ->
    fd = screen.rfd
    if screen.raw and fd\tcsetattr('FLUSH', screen.old_termios)
      screen.raw = false

  columns = (screen) ->
    size = S.ioctl screen.wfd, 'TIOCGWINSZ'
    return 80 unless size or size.ws_col == 0
    size.ws_col

  clear = (screen) -> screen.wfd\write '\x1b[H\x1b[2J'

  beep = (screen) -> screen.wfd\write '\x07'

  cmdline = new_cmdline!
  :notify, :reload_spook = _G

  cmdline\cmd "reload", "Reload spook", (screen) ->
    notify.info "Reloading spook..."
    reload_spook!

  cmdline\cmd "history", "Show history", (screen) ->
    for id, line in ipairs history
      print "#{id}: " .. concat(line, '')

  cmdline\cmd "exit", "Exit spook", (screen) ->
    S.kill S.getpid!, "int"

  cmdline\cmd "setenv", "<key> [value] sets an environment variable (no value unsets it)", (screen, key, value) ->
    return unless key
    notify.info "current: #{key}=#{os.getenv(key)}"
    if value
      S.setenv(key, value, true)
    else
      S.unsetenv(key)
    notify.info "new: #{key}=#{os.getenv(key)}"

  cmdline\cmd "getenv", "[key] prints an environment variable (no key prints all variables)", (screen, key) ->
    if key
      print "#{key}=#{os.getenv(key)}"
    else
      keys = {}
      for k, v in pairs S.environ!
        insert keys, "#{k}=#{v}"
      print concat(keys,"\n")

  cmdline\cmd "help", "Shows this help message", (screen) ->
    :wfd = screen
    max_len = 0
    for cmd in pairs cmdline
      continue if cmd == '__dynamic'
      max_len = max max_len, #cmd

    out = {}
    for cmd, def in pairs cmdline
      continue if cmd == '__dynamic'
      spaces = (' ')\rep((max_len - #cmd) + 2)
      insert out, white(cmd)
      insert out, spaces
      insert out, def[2]
      insert out, '\n'

    wfd\write concat(out,'')

  cmdline\cmd "->", "<code here> will parse and execute as moonscript", (...) ->
    args = {...}
    screen = args[1]
    rest = [item for idx, item in ipairs args when idx > 1]
    code = concat rest, ' '
    tree, err = parse.string code
    unless tree
      beep screen
      screen.wfd\write red("Parse error: " .. err .. '\n')
      return
    lua_code, err, pos = compile.tree tree
    unless lua_code
      screen.wfd\write red(compile.format_error(err, pos, code) .. '\n')
      return

    chunk = loadstring lua_code
    print chunk!

  local complete
  suggestions = {}
  suggested = 0

  reset_completion = ->
    suggestions = {}
    suggested = 0

  complete = (screen) ->
    suggested += 1
    suggested = 1 if suggested > #suggestions
    if s = suggestions[suggested]
      screen.line = s
      screen.pos = #s + 1
      return
    line = screen.line
    sline = concat line, ''
    for name in pairs cmdline
      matches = {name\match "^#{sline\escape_pattern!}"}
      if #matches > 0
        insert suggestions, name\split!
    complete screen if #suggestions > 0

  km = new_keymap!
  esckm = new_keymap!
  okm = new_keymap!

  ctrl = (char) -> char\upper!\byte!-64

  km\mapkey ctrl('c'), (screen) ->
    reset_completion!
    history\reset_pos!
    disable_raw screen
    S.kill S.getpid!, 'int'
    true

  km\mapkey '\r', (screen) ->
    reset_completion!
    disable_raw screen
    screen.wfd\write '\n'
    history\add screen.line
    true

  km\mapkey 127, (screen) ->
    reset_completion!
    :line, :pos = screen
    if pos > 1 and #line > 0
      screen.pos -= 1
      remove screen.line, screen.pos

  km\mapkey ctrl('d'), (screen) ->
    reset_completion!
    disable_raw screen
    screen.wfd\write '\n'
    history\add screen.line
    true

  km\mapkey ctrl('u'), (screen) ->
    reset_completion!
    screen.line = {}
    screen.pos = 1

  km\mapkey ctrl('l'), (screen) ->
    clear screen

  km\mapkey 9, complete

  -- escape
  km\mapkey 27, (screen) ->
    nxt = read(screen.rfd, 1)!
    byte = nxt\byte 1
    if m = esckm\keymap(tobyte(byte))
      m screen

  -- escape sub mapping
  esckm\mapkey 91, (screen) ->
    nxt = read(screen.rfd, 1)!
    byte = nxt\byte 1
    if m = okm\keymap(tobyte(byte))
      m screen

  -- left arrow
  okm\mapkey 'D', (screen) ->
    if screen.pos > 1
      screen.pos -= 1

  -- right arrow
  okm\mapkey 'C', (screen) ->
    if screen.pos <= #screen.line
      screen.pos += 1

  -- up arrow
  okm\mapkey 'A', (screen) ->
    if line = history\back!
      screen.line = line
      screen.pos = #line + 1

  -- down arrow
  okm\mapkey 'B', (screen) ->
    if line = history\forward!
      screen.line = line
      screen.pos = #line + 1
    else
      screen.line = {}
      screen.pos = 1

  refresh = (screen) ->
    fd = screen.wfd
    :line, :pos = screen
    prompt = get_prompt!
    plen = #prompt
    cols = columns screen

    if plen + pos >= cols - 1
      line = line[plen+pos-cols+1]
      pos = cols
    if plen + #line > cols
      line = [c for i, c in ipairs line when i < cols-plen]
    -- cursor to left edge
    assert fd\write '\x1b[0G'
    -- write prompt + buffer
    assert fd\write blue(prompt)
    assert fd\write concat line, ''
    -- erase anything after
    assert fd\write '\x1b[0K'
    -- move cursor to current pos
    assert fd\write '\x1b[0G\x1b[' .. tostring(pos + plen - 1) .. 'C'


  edit = (screen) ->
    for c, err in read(screen.rfd, 1)
      break if err
      byte = c\byte!
      if mapping = km\keymap byte
        break if mapping(screen) == true
      else
        insert screen.line, screen.pos, c
        screen.pos += 1
      refresh screen


  tokenize = (line) -> line\split(' ')

  new_screen = (rfd, wfd) ->
    {
      :rfd
      :wfd
      line: {}
      pos: 1
    }

  repl = (r, fd) ->
    screen = new_screen fd, S.stdout
    enable_raw screen
    refresh screen
    edit screen
    disable_raw screen
    line = concat screen.line, ''
    tokens = tokenize line
    return unless #tokens > 0
    if def = cmdline[tokens[1]]
      args = [a for i, a in ipairs tokens when i > 1]
      c = def[1]
      c screen, unpack(args)
    reset_completion!

  :repl, :cmdline
