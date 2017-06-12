insert: append, :concat = table

to_func = (callable) ->
  (...) -> callable ...

coro = (func, ...) ->
  coroutine.wrap(to_func(func)) ...

to_coro = (func) ->
  (...) -> coro(func, ...)

read = (fd, count = 4096) -> ->
  bytes, err = fd\read nil, count
  return "", err if err
  return nil if #bytes == 0
  bytes

NEWLINE = string.byte '\n'
readline = (fd) ->
  line = {}
  getline = ->
    for bytes, err in read(fd)
      coroutine.yield nil, err if err
      for i=1, #bytes
        if bytes\byte(i) == NEWLINE
          coroutine.yield concat(line, '')
          line = {}
          continue
        append line, bytes\sub(i,i)
  coroutine.wrap -> getline!

{
  is_callable: (thing) ->
    t = type thing
    return true if t == 'function'
    mt = getmetatable thing
    return true if mt and mt.__call
    false

  :to_func
  :to_coro
  :read
  :readline
}
