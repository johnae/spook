describe "notify", ->
  local notify

  before_each ->
    notify = require("notify")!

  it "notifies all registered notifiers", ->

    n1 = {
      start: spy.new -> nil
      finish: spy.new -> nil
    }
    n2 = {
      start: spy.new -> nil
      finish: spy.new -> nil
    }
    notify[#notify + 1] = n1
    notify[#notify + 1] = n2
    notify.start "spec", "called"
    assert.spy(n1.start).was.called_with "spec", "called"
    assert.spy(n2.start).was.called_with "spec", "called"
    notify.finish true, "spec", "called", 10
    assert.spy(n1.finish).was.called_with true, "spec", "called", 10
    assert.spy(n2.finish).was.called_with true, "spec", "called", 10
