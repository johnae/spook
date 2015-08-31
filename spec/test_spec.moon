describe 'test', ->
  before_each ->
    print "Running before"

  describe 'something', ->

    it 'runs', ->
      assert(1,1)
