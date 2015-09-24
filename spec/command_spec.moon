command = require "command"

describe "command", ->

  it "generates command lines", ->
    cmd = command "ls -lah"
    assert.same {cmd: "ls -lah"}, cmd
