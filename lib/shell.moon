S = require 'syscall'
:read, :is_callable = require 'utils'
:new_cmdline, :new_keymap, :tobyte, :red, :blue = require 'shell_utils'
parse = require 'moonscript.parse'
compile = require 'moonscript.compile'
:insert, :concat, :remove = table

(prompt) ->
  history = {}
  history_idx = 1
  history_insert = (line) ->
    if line and #line > 0
      for i, l in ipairs history
        l1 = concat line, ''
        l2 = concat l, ''
        if l1 == l2
          remove history, i
      insert history, line
      history_idx = #history + 1

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

  cmdline\cmd "reload", " - reloads spook", (screen) ->
    notify.info "Reloading spook..."
    reload_spook!

  cmdline\cmd "history", " - show history", (screen) ->
    for id, line in ipairs history
      print "#{id}: " .. concat(line, '')

  cmdline\cmd "exit", " - exits spook", (screen) ->
    S.kill S.getpid!, "int"

  cmdline\cmd "setenv", "KEY VALUE - sets an environment variable (no value unsets it)", (screen, key, value) ->
    return unless key
    notify.info "current: #{key}=#{os.getenv(key)}"
    if value
      S.setenv(key, value, true)
    else
      S.unsetenv(key)
    notify.info "new: #{key}=#{os.getenv(key)}"

  cmdline\cmd "getenv", "KEY - gets an environment variable", (screen, key) ->
    if key
      print "#{key}=#{os.getenv(key)}"
    else
      keys = {}
      for k, v in pairs S.environ!
        insert keys, "#{k}=#{v}"
      print concat(keys,"\n")

  cmdline\cmd "help", " - shows this help message", (screen) ->
    for cmd, def in pairs cmdline
      continue if cmd == '__dynamic'
      print "#{cmd} #{def[2]}"

  cmdline\cmd "->", "CODE - will parse and execute as moonscript", (...) ->
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

  km = new_keymap!
  esckm = new_keymap!
  okm = new_keymap!

  ctrl = (char) -> char\upper!\byte!-64

  km\mapkey ctrl('c'), (screen) ->
    history_idx = #history + 1
    disable_raw screen
    S.kill S.getpid!, 'int'
    true

  km\mapkey '\r', (screen) ->
    disable_raw screen
    screen.wfd\write '\n'
    history_insert screen.line
    true

  km\mapkey 127, (screen) ->
    :line, :pos = screen
    if pos > 1 and #line > 0
      screen.pos -= 1
      remove screen.line, screen.pos

  km\mapkey ctrl('d'), (screen) ->
    disable_raw screen
    screen.wfd\write '\n'
    history_insert screen.line
    true

  km\mapkey ctrl('u'), (screen) ->
    screen.line = {}
    screen.pos = 1

  km\mapkey ctrl('l'), (screen) ->
    clear screen

  km\mapkey 9, (screen) ->
    line = screen.line
    sline = concat line, ''
    for name in pairs cmdline
      matches = {name\match "^#{sline\escape_pattern!}"}
      if #matches > 0
        screen.line = name\split!
        screen.pos = #screen.line+1

  -- escape
  km\mapkey 27, (screen) ->
    nxt = read(screen.rfd, 1)!
    byte = nxt\byte 1
    esckm\keymap(tobyte(byte)) screen

  -- escape sub mapping
  esckm\mapkey 91, (screen) ->
    nxt = read(screen.rfd, 1)!
    byte = nxt\byte 1
    okm\keymap(tobyte(byte)) screen

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
    at = history_idx-1
    if at > 0
      history_idx = at
      line = history[at]
      screen.line = line
      screen.pos = #line + 1

  -- down arrow
  okm\mapkey 'B', (screen) ->
    at = history_idx+1
    if at <= #history
      history_idx = at
      line = history[at]
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
    --if line[#line] == '\n'
    --  assert fd\write '\x1b[0B'
    -- write prompt + buffer
    assert fd\write blue(prompt)
    assert fd\write concat line, ''
    -- erase to right
    assert fd\write '\x1b[0K'
    -- move cursor to pos
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

  :repl, :cmdline
