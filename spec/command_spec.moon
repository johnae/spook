command = require "command"

describe "command", ->
  local mapping, mapper, os_exec, real_exec
  match = require "luassert.match"

  before_each ->
    real_exec = os.execute
    os_exec = spy.new -> nil, nil, 0
    os.execute = os_exec

  after_each ->
    os.execute = real_exec

  it "generates command lines", ->
    cmd = command "ls -lah"
    assert.same {cmd: "ls -lah"}, cmd

  it "calls the command with the specified file", ->
    cmd = command "ls -lah"
    assert.same {cmd: "ls -lah"}, cmd
    info, run = cmd "/tmp"
    run!
    assert.spy(os_exec).was_called_with "ls -lah /tmp"

  it "by default skips running the command when file does not exist", ->
    cmd = command "ls -lah"
    assert.same {cmd: "ls -lah"}, cmd
    info, run = cmd "/tmp/vffhasddiahdgadhgjabsfuahsifadisndjnuqh83283uwg"
    assert.nil info
    assert.nil run

  it "expands placeholder for file", ->
    cmd = command "ls -lah [file] | wc -l > [file].count"
    assert.same {cmd: "ls -lah [file] | wc -l > [file].count"}, cmd
    info, run = cmd "/tmp"
    run!
    assert.spy(os_exec).was_called_with "ls -lah /tmp | wc -l > /tmp.count"

  describe "failure", ->

    before_each ->
      -- always return non-zero exit status
      os_exec = spy.new -> nil, nil, 1
      os.execute = os_exec

    it "returns false when running the command by default", ->
      cmd = command "echo '[file]'"
      info, run = cmd "/tmp"
      assert.false run!

    it "returns true when the command was created with option allow_fail: true", ->
      cmd = command "echo '[file]'", allow_fail: true
      info, run = cmd "/tmp"
      assert.true run!

    it "returns true when the command is run with option allow_fail: true", ->
      cmd = command "echo '[file]'"
      info, run = cmd "/tmp", allow_fail: true
      assert.true run!
