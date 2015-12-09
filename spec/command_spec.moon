command = require "command"

describe "command", ->
  local mapping, mapper, os_exec, real_exec
  match = require "luassert.match"

  before_each ->
    real_exec = os.execute
    os_exec = spy.new -> true
    os.execute = os_exec

  after_each ->
    os.execute = real_exec

  it "generates command lines", ->
    cmd = command "ls -lah"
    assert.same {cmd: "ls -lah"}, cmd

  it "calls the command with the specified file", ->
    cmd = command "ls -lah"
    assert.same {cmd: "ls -lah"}, cmd
    note, exec = cmd "/tmp"
    exec!
    assert.spy(os_exec).was_called_with "ls -lah /tmp"

  it "by default skips running the command when file does not exist", ->
    cmd = command "ls -lah"
    assert.same {cmd: "ls -lah"}, cmd
    note, exec = cmd "/tmp/vffhasddiahdgadhgjabsfuahsifadisndjnuqh83283uwg"
    assert.nil note
    assert.nil run

  it "expands placeholder for file", ->
    cmd = command "ls -lah [file] | wc -l > [file].count"
    assert.same {cmd: "ls -lah [file] | wc -l > [file].count"}, cmd
    note, exec = cmd "/tmp"
    exec!
    assert.spy(os_exec).was_called_with "ls -lah /tmp | wc -l > /tmp.count"
