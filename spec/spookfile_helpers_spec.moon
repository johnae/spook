describe "spookfile_helpers", ->
  local helpers, old_log

  before_each ->
    old_log = _G.log
    _G.log = {
      info: ->
      error: ->
      warn: ->
      debug: ->
    }
    helpers = require 'spookfile_helpers'

  after_each -> _G.log = old_log

  describe 'until_success', ->

    it 'reexecutes previous given function if it failed - regardless of input', ->
      fail = true
      func = spy.new ->
        if fail
          error "oopsie"
        true
      func2 = spy.new -> true

      assert.error -> helpers.until_success(func), 'oopsie'
      fail = false
      helpers.until_success(func2)
      -- but only func should be called
      assert.spy(func).was.called(2)
      -- until it succeeded
      helpers.until_success(func2)
      assert.spy(func2).was.called(1)

  describe 'task_filter', ->

    it 'lets through those tasks the filter returns a true value for', ->
      filter = helpers.task_filter (input) ->
        return false unless input == 'must be this'
        true

      func1 = spy.new -> true
      func2 = spy.new -> true
      func3 = spy.new -> true

      tasks = filter(
        func1, 'must be this'
        func2, 'not this'
        func3, 'must be this'
      )

      for task, args in tasks
        task args

      assert.spy(func1).was.called.with 'must be this'
      assert.spy(func2).was.not.called!
      assert.spy(func3).was.called.with 'must be this'
