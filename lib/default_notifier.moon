start = (changed_file, mapped_file) -> print "file: #{changed_file}"
finish = (status, changed_file, mapped_file) -> print "done: #{status}"

:start, :finish
