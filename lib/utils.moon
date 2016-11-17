{
  is_callable: (thing) ->
    t = type thing
    return true if t == 'function'
    mt = getmetatable thing
    return true if mt and mt.__call
    false
}
