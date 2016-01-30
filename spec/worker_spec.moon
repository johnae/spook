fs = require "fs"
worker = require "worker"

describe "worker", ->
  local spook, runner, changes, timer
  match = require "luassert.match"
  test_file1 = "/tmp/spook-test-file1"
  test_file2 = "/tmp/spook-test-file2"

  before_each ->
    f = assert(io.open(test_file1, "w"))
    f\write("hello")
    f\close!
    f = assert(io.open(test_file2, "w"))
    f\write("hello")
    f\close!
    spook = {
      start: spy.new -> nil
      clear: spy.new -> nil
    }
    changes, timer = worker(spook)
    changes[test_file1] = -> 
      -> description: "run #{test_file1}", detail: "#{test_file1}", -> true
    changes[test_file2] = -> 
      -> description: "run #{test_file2}", detail: "#{test_file2}", -> true

  after_each ->
    fs.rm_rf test_file1
    fs.rm_rf test_file2

  it "runs all functions for current changes", ->
    run_uv_for 300
    assert.spy(spook.start).was.called(2)
    assert.spy(spook.clear).was.called(1)
