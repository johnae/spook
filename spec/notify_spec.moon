gettimeofday = gettimeofday

describe "notify", ->
  local notify

  before_each ->
    notify = require("notify")!

  it "notifies all registered notifiers", ->

    info = something: 'here'
    desc = 'blah'
    -- not perfect, therefore testing using is.near
    n1_start_at = nil
    n1_success_at = nil
    n2_start_at = nil
    n2_fail_at = nil
    n1 = {
      start: spy.new (name, data) ->
        n1_start_at or= gettimeofday! / 1000.0
        assert.equal desc, name
        assert.equal info.something, data.something
        assert.is.near n1_start_at*1000, data.start_at*1000, 10
      success: spy.new (name, data) ->
        n1_success_at or= gettimeofday! / 1000.0
        assert.equal desc, name
        assert.equal info.something, data.something
        assert.is.near n1_start_at*1000, data.start_at*1000, 10
        assert.is.near n1_success_at*1000, data.success_at*1000, 10
    }
    n2 = {
      start: spy.new (name, data) ->
        n2_start_at or= gettimeofday! / 1000.0
        assert.equal desc, name
        assert.equal info.something, data.something
        assert.is.near n2_start_at*1000, data.start_at*1000, 10
      fail: spy.new (name, data) ->
        n2_fail_at or= gettimeofday! / 1000.0
        assert.equal desc, name
        assert.equal info.something, data.something
        assert.is.near n2_start_at*1000, data.start_at*1000, 10
        assert.is.near n2_fail_at*1000, data.fail_at*1000, 10
    }
    notify.add n1, n2
    notify.start 'blah', info
    assert.spy(n1.start).was.called 1
    assert.spy(n2.start).was.called 1
    notify.success 'blah', info
    assert.spy(n1.success).was.called 1
    notify.fail 'blah', info
    assert.spy(n2.fail).was.called 1
