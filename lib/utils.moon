to_func = (callable) ->
  (...) -> callable ...

coro = (func, ...) ->
  coroutine.wrap(to_func(func)) ...

to_coro = (func) ->
  (...) -> coro(func, ...)

{
  is_callable: (thing) ->
    t = type thing
    return true if t == 'function'
    mt = getmetatable thing
    return true if mt and mt.__call
    false

  :to_func
  :to_coro
  :coro
}
