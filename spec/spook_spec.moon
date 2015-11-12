-- these specs are very sensitive and also
-- depend on the system they're running on
-- that's why the watch time is quite generous (1500 ms),
-- unfortunately that means these are slow (compared to the
-- other specs)

lfs = require "syscall.lfs"
fs = require "fs"
dir_list = require "dir_list"
uv = require "uv"
spook = require "spook"

describe 'spook', ->
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
      spook {:mapper, :watch}
      watch_for(1500)
      create_file(300, file)
      uv.update_time!
      uv\run!
      assert.spy(mapper).was_called(1)

    it 'when a file is changed', ->
      watch = dir_list(dir2)
      file = "#{dir2}/myfile.txt"
      f = assert(io.open(file, "w"))
      f\write("hello")
      f\close!
      spook {:mapper, :watch}
      watch_for(1500)
      update_file(300, file)
      uv.update_time!
      uv\run!
      assert.spy(mapper).was_called(1)


    it 'when a file is deleted', ->
      watch = dir_list(dir3)
      file = "#{dir3}/myfile.txt"
      f = assert(io.open(file, "w"))
      f\write("hello")
      f\close!
      spook {:mapper, :watch}
      watch_for(1500)
      delete_file(300, file)
      uv.update_time!
      uv\run!
      assert.spy(mapper).was_not_called
