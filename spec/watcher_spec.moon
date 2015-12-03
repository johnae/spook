-- These specs are very sensitive and also
-- depend on the system they're running on
-- that's why the watch time is quite generous.
-- Unfortunately that means these are slow.

lfs = require "syscall.lfs"
fs = require "fs"
dir_list = require "dir_list"
uv = require "uv"
watcher = require "watcher"

describe 'watcher', ->
  local dir1, dir2, dir3, mapper

  timers = {}

  create_file = (time, file) ->
    timer = uv.new_timer!
    timers[#timers + 1] = timer
    timer\start time, 0, ->
      f = assert(io.open(file, "w"))
      f\write("hello")
      f\close!

  update_file = (time, file) ->
    timer = uv.new_timer!
    timers[#timers + 1] = timer
    timer\start time, 0, ->
      f = assert(io.open(file, "a+"))
      f\write("update")
      f\close!

  delete_file = (time, file) ->
    timer = uv.new_timer!
    timers[#timers + 1] = timer
    timer\start time, 0, ->
      os.remove file

  watch_for = (time) ->
    timer = uv.new_timer!
    timer\start time, 0, ->
      timer\close!
      uv\stop!

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
    for timer in *timers
      timer\close!
    timers = {}
    fs.rm_rf "/tmp/spook-spec-base"

  describe 'file system notifications', ->

    it 'when a new file is added', ->
      watch = dir_list(dir1)
      file = "#{dir1}/myfile.txt"
      watcher {:mapper, :watch}
      watch_for(2000)
      create_file(500, file)
      uv.update_time!
      uv\run!
      assert.spy(mapper).was_called(1)

    it 'when a file is changed', ->
      watch = dir_list(dir2)
      file = "#{dir2}/myfile.txt"
      f = assert(io.open(file, "w"))
      f\write("hello")
      f\close!
      watcher {:mapper, :watch}
      watch_for(2000)
      update_file(500, file)
      uv.update_time!
      uv\run!
      assert.spy(mapper).was_called(1)


    it 'when a file is deleted', ->
      watch = dir_list(dir3)
      file = "#{dir3}/myfile.txt"
      f = assert(io.open(file, "w"))
      f\write("hello")
      f\close!
      watcher {:mapper, :watch}
      watch_for(2000)
      delete_file(500, file)
      uv.update_time!
      uv\run!
      assert.spy(mapper).was_not_called
