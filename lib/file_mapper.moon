map = (mapping, changed_file) ->
  for matcher, mapper in pairs mapping
    matches = {changed_file\match matcher}
    if #matches > 0
      return mapper unpack(matches)

(file_mapping) ->
  (changed_file) ->
    if #file_mapping > 0
      for mapping in *file_mapping
        if mapped = map(mapping, changed_file)
          return mapped
    else
      return map(file_mapping, changed_file)
