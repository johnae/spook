(file_mapping) ->
  (changed_file) ->
    for matcher, mapper in pairs file_mapping
      matches = {changed_file\match matcher}
      if #matches>0
        return mapper(unpack(matches))
    return nil
