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

  it 'can take a peek at either end of the queue', ->
    queue\pushleft 'item1'
    queue\pushleft 'item2'
    queue\pushleft 'item3'
    assert.equal 'item3', queue\peekleft!
    assert.equal 'item1', queue\peekright!

  it 'can take a peek at any element of the queue', ->
    queue\pushright 'item1'
    queue\pushright 'item2'
    queue\pushright 'item3'
    queue\pushright 'item4'
    assert.equal 'item2', queue\peek(1)
    assert.equal 'item4', queue\peek(3)
    queue\popleft!
    assert.equal 'item2', queue\peek(0)
    assert.equal 'item4', queue\peek(2)
    queue\pushleft 'something'
    assert.equal 'something', queue\peek(0)
    assert.equal 'item2', queue\peek(1)
    assert.equal 'item4', queue\peek(3)
    queue\pushright 'something2'
    assert.equal 'something', queue\peek(0)
    assert.equal 'item2', queue\peek(1)
    assert.equal 'item4', queue\peek(3)
    assert.equal 'something2', queue\peek(4)

  it 'can reset itself to be empty', ->
    queue\pushleft 'item1'
    queue\pushleft 'item2'
    queue\pushleft 'item3'
    assert.equal 'item3', queue\peekleft!
    assert.equal 'item1', queue\peekright!
    assert.equal 3, #queue
    queue\reset!
    assert.equal 0, #queue
    assert.equal nil, queue\peekleft!
    assert.equal nil, queue\peekright!
