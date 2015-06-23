(file_mapping) ->
  (changed_file) ->
    for matcher, mapper in pairs(file_mapping) do
      a, b = changed_file\match matcher
      if a and b
        return mapper(a,b)
    return nil
