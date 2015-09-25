map = (mapping, changed_file) ->
  matcher, mapper = mapping[1], mapping[2]
  matches = {changed_file\match matcher}
  if #matches > 0
    return -> mapper unpack(matches)

(file_mapping) ->
  (changed_file) ->
    for mapping in *file_mapping
      if mapped = map(mapping, changed_file)
        return mapped
