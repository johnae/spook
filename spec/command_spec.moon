command = require "command"

describe "command", ->
  local mapping, mapper, os_exec, real_exec, dummy_notify

  before_each ->
    real_exec = os.execute
    os_exec = spy.new -> true
    os.execute = os_exec
    dummy_notify = {
      start: spy.new -> nil
      finish: spy.new -> nil
    }

  after_each ->
    os.execute = real_exec

  it "generates command lines", ->
    cmd = command "ls -lah"
    assert.same {cmd: "ls -lah"}, cmd

  it "calls the notify api", ->
    cmd = command "ls -lah", notify: dummy_notify
    assert.same {cmd: "ls -lah"}, cmd
    cmd "/tmp"
    assert.spy(dummy_notify.start).was_called_with("ls -lah /tmp", "/tmp")
    assert.spy(dummy_notify.finish).was_called(1)

  it "calls the command with the specified file", ->
    cmd = command "ls -lah", notify: dummy_notify
    assert.same {cmd: "ls -lah"}, cmd
    cmd "/tmp"
    assert.spy(os_exec).was_called_with("ls -lah /tmp")

  it "expands placeholder for file", ->
    cmd = command "ls -lah [file] | wc -l > [file].count", notify: dummy_notify
    assert.same {cmd: "ls -lah [file] | wc -l > [file].count"}, cmd
    cmd "/tmp"
    assert.spy(os_exec).was_called_with("ls -lah /tmp | wc -l > /tmp.count")
