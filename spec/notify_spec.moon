gettimeofday = gettimeofday

describe "notify", ->
  local notify

  before_each ->
    notify = require("notify")!

  it "notifies all registered notifiers", ->

    info = something: 'here'
    desc = 'blah'
    started_at = nil
    ended_at = nil
    n1 = {
      start: spy.new (name, event) ->
        -- TODO: this is stupid and might fail occasionally
        started_at or= gettimeofday! / 1000.0
        assert.equal desc, name
        assert.same {something: info.something, :started_at}, event
      success: spy.new (name, event) ->
        -- TODO: this is stupid and might fail occasionally
        ended_at or= gettimeofday! / 1000.0
        assert.equal desc, name
        assert.same {something: info.something, :started_at, :ended_at}, event
    }
    n2 = {
      start: spy.new (name, event) ->
        -- TODO: this is stupid and might fail occasionally
        started_at or= gettimeofday! / 1000.0
        assert.equal desc, name
        assert.same {something: info.something, :started_at}, event
      fail: spy.new (name, event) ->
        -- TODO: this is stupid and might fail occasionally
        ended_at or= gettimeofday! / 1000.0
        assert.equal desc, name
        assert.same {something: info.something, :started_at, :ended_at}, event
    }
    notify.add n1
    notify.add n2
    notify.start 'blah', info
    assert.spy(n1.start).was.called 1
    assert.spy(n2.start).was.called 1
    notify.success 'blah', info
    assert.spy(n1.success).was.called 1
    notify.fail 'blah', info
    assert.spy(n2.fail).was.called 1
