fs = require "fs"
worker = require "worker"
{:func} = require "runners"

describe "worker", ->
  local spec_handler, changes, timer
  test_file1 = "/tmp/spook-test-file1"
  test_file2 = "/tmp/spook-test-file2"

  before_each ->
    f = assert(io.open(test_file1, "w"))
    f\write("hello")
    f\close!
    f = assert(io.open(test_file2, "w"))
    f\write("hello")
    f\close!
    spec_handler = spy.new -> true
    spec_runner = func name: "spec_runner", handler: spec_handler
    changes, timer = worker!
    changes[test_file1] = -> 
      -> spec_runner "test_file1"
    changes[test_file2] = -> 
      -> spec_runner "test_file2"

  after_each ->
    fs.rm_rf test_file1
    fs.rm_rf test_file2

  it "runs all functions for current changes", ->
    run_uv_for 300
    assert.spy(spec_handler).was.called(2)
