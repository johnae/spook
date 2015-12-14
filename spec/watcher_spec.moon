-- These specs are very sensitive and also
-- depend on the system they're running on
-- that's why the watch time is quite generous.
-- Unfortunately that means these are slow.

fs = require "fs"
dir_list = require "dir_list"
watcher = require "watcher"

describe 'watcher', ->
  local dir1, dir2, dir3, mapper

  timers = {}

  before_each ->
    fs.rm_rf "/tmp/spook-spec-base"
    dir1 = "/tmp/spook-spec-base/spook-spec1"
    dir2 = "/tmp/spook-spec-base/spook-spec2"
    dir3 = "/tmp/spook-spec-base/spook-spec3"
    fs.mkdir_p dir1
    fs.mkdir_p dir2
    fs.mkdir_p dir3
    mapper = spy.new ->

  after_each ->
    fs.rm_rf "/tmp/spook-spec-base"

  describe 'file system notifications', ->

    it 'when a new file is added', ->
      watch = dir_list(dir1)
      file = "#{dir1}/myfile.txt"
      changes = {}
      watcher {:mapper, :watch, :changes}
      create_file_after 500, file
      run_uv_for 2000
      assert.same {"#{dir1}/myfile.txt": mapper}, changes

    it 'when a file is changed', ->
      watch = dir_list(dir2)
      file = "#{dir2}/myfile.txt"
      changes = {}
      create_file file, "hello"
      watcher {:mapper, :watch, :changes}
      update_file_after 500, file
      run_uv_for 2000
      assert.same {"#{dir2}/myfile.txt": mapper}, changes

    it 'when a file is deleted', ->
      watch = dir_list(dir3)
      file = "#{dir3}/myfile.txt"
      changes = {}
      create_file file, "hello"
      watcher {:mapper, :watch, :changes}
      delete_file_after 500, file
      run_uv_for 2000
      assert.same {"#{dir3}/myfile.txt": mapper}, changes
