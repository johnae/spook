dir_list = require "dir_list"
fs = require "fs"

describe 'dir_list', ->
  local dir

  before_each ->
    dir = "/tmp/spook-spec"
    dir_structure = "#{dir}/dir1/sub2/sub3"
    fs.mkdir_p dir_structure
    f = assert(io.open("#{dir}/dir1/sub2/file.txt", "w"))
    f\write("hello")
    f\close!

  after_each ->
    fs.rm_rf dir

  it 'only lists directories including the top dir', ->
    dirs = dir_list dir
    assert.same {
      dir,
      "#{dir}/dir1",
      "#{dir}/dir1/sub2",
      "#{dir}/dir1/sub2/sub3"
    }, dirs
