command = require "command"

describe "command", ->
  local mapping, mapper, os_exec, real_exec, dummy_spook
  match = require "luassert.match"

  before_each ->
    real_exec = os.execute
    os_exec = spy.new -> true
    os.execute = os_exec
    dummy_spook = {
      start: spy.new (info, fn) -> fn!
    }

  after_each ->
    os.execute = real_exec

  it "generates command lines", ->
    cmd = command "ls -lah"
    assert.same {cmd: "ls -lah"}, cmd

  --it "calls the run api", ->
  --  cmd = command "ls -lah", run: dummy_run
  --  assert.same {cmd: "ls -lah"}, cmd
  --  cmd "/tmp"
  --  expected_info = match.is_same(description: "ls -lah /tmp", detail: "/tmp")
  --  assert.spy(dummy_run.start).was_called_with(expected_info)

  it "calls the command with the specified file", ->
    cmd = command "ls -lah", run: dummy_run
    assert.same {cmd: "ls -lah"}, cmd
    cmd "/tmp"
    assert.spy(os_exec).was_called_with "ls -lah /tmp"

  it "by default skips running the command when file does not exist", ->
    cmd = command "ls -lah", run: dummy_run
    assert.same {cmd: "ls -lah"}, cmd
    cmd "/tmp/vffhasddiahdgadhgjabsfuahsifadisndjnuqh83283uwg"
    assert.spy(os_exec).was_not_called!

  it "expands placeholder for file", ->
    cmd = command "ls -lah [file] | wc -l > [file].count", run: dummy_run
    assert.same {cmd: "ls -lah [file] | wc -l > [file].count"}, cmd
    cmd "/tmp"
    assert.spy(os_exec).was_called_with "ls -lah /tmp | wc -l > /tmp.count"
