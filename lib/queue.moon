define = require'classy'.define

define 'Queue', ->
  instance
    initialize: =>
      @first = 0
      @last = -1
      @list = {}
      @len = 0

    pushleft: (value) =>
      @first = @first - 1
      @list[@first] = value
      @len += 1

    pushright: (value) =>
      @last = @last + 1
      @list[@last] = value
      @len += 1

    popleft: (value) =>
      error 'Queue is empty' if @first > @last
      value = @list[@first]
      @list[@first] = nil
      @first = @first + 1
      @len -= 1
      value

    popright: (value) =>
      error 'Queue is empty' if @first > @last
      value = @list[@last]
      @list[@last] = nil
      @last = @last - 1
      @len -= 1
      value

  meta
    __len: => @len
