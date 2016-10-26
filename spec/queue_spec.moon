Queue = require 'queue'

describe 'Queue', ->
  local queue

  before_each ->
    queue = Queue.new!

  it 'has length of 0 when initialized', ->
    assert.equal 0, #queue

  it 'has length of 1 with 1 item', ->
    queue\pushright {}
    assert.equal 1, #queue

  it 'has length of 2 with 2 items', ->
    queue\pushright {}
    queue\pushleft {}
    assert.equal 2, #queue

  it 'has length of 1 after removing item from queue with 2 items', ->
    queue\pushright {}
    queue\pushleft {}
    queue\popleft!
    assert.equal 1, #queue
    queue\pushleft {}
    queue\popright!
    assert.equal 1, #queue

  it 'maintains length properly throughout pushing and popping', ->
    queue\pushright 'item'
    queue\pushright 'item'
    queue\pushright 'item'
    assert.equal 3, #queue
    queue\pushleft 'item'
    queue\pushleft 'item'
    assert.equal 5, #queue
    queue\popright!
    assert.equal 4, #queue
    queue\popleft!
    assert.equal 3, #queue
    queue\pushright 'item'
    assert.equal 4, #queue
    for i=1,4
      queue\popleft!
    assert.equal 0, #queue

  it 'pops the expected item of the right end', ->
    queue\pushleft 'item1'
    queue\pushleft 'item2'
    assert.equal 'item1', queue\popright!
    queue\pushright 'last'
    assert.equal 'last', queue\popright!

  it 'pops the expected item of the left end', ->
    queue\pushleft 'item1'
    queue\pushright 'item2'
    assert.equal 'item1', queue\popleft!
    assert.equal 'item2', queue\popleft!
