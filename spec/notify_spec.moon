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
    info = description: "spec", detail: "called"
    notify.start info
    assert.spy(n1.start).was.called_with info
    assert.spy(n2.start).was.called_with info
    info.elapsed_time = 10.42
    notify.finish true, info
    assert.spy(n1.finish).was.called_with true, info
    assert.spy(n2.finish).was.called_with true, info
