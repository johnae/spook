gettimeofday = gettimeofday

describe "notify", ->
  local notify

  before_each ->
    notify = require("notify")!

  it "notifies all registered notifiers", ->

    info = something: 'here'
    desc = 'blah'
    -- not perfect, therefore testing using is.near
    n1_started_at = nil
    n1_ended_at = nil
    n2_started_at = nil
    n2_ended_at = nil
    n1 = {
      start: spy.new (name, event) ->
        n1_started_at or= gettimeofday! / 1000.0
        assert.equal desc, name
        assert.equal info.something, event.something
        assert.is.near n1_started_at*1000, event.started_at*1000, 10
      success: spy.new (name, event) ->
        n1_ended_at or= gettimeofday! / 1000.0
        assert.equal desc, name
        assert.equal info.something, event.something
        assert.is.near n1_started_at*1000, event.started_at*1000, 10
        assert.is.near n1_ended_at*1000, event.ended_at*1000, 10
    }
    n2 = {
      start: spy.new (name, event) ->
        n2_started_at or= gettimeofday! / 1000.0
        assert.equal desc, name
        assert.equal info.something, event.something
        assert.is.near n2_started_at*1000, event.started_at*1000, 10
      fail: spy.new (name, event) ->
        n2_ended_at or= gettimeofday! / 1000.0
        assert.equal desc, name
        assert.equal info.something, event.something
        assert.is.near n2_started_at*1000, event.started_at*1000, 10
        assert.is.near n2_ended_at*1000, event.ended_at*1000, 10
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
