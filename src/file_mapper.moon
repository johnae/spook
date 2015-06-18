(file_mapping) ->
  (changed_file) ->
    for matcher, mapper in pairs(file_mapping) do
      a, b = changed_file\match matcher
      return mapper(a,b) if a and b
    return nil
