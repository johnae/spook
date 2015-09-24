lfs = require "syscall.lfs"
fs = require "fs"
dir_list = require "dir_list"
uv = require "uv"
spook = require "spook"

describe 'spook', ->
  local dirs, mapper, dir

  create_file = (time, file) ->
    timer = uv.new_timer!
    timer\start time, 0, ->
      f = assert(io.open(file, "w"))
      f\write("hello")
      f\close!
      timer\stop!
      timer\close!

  watch_for = (time) ->
    timer = uv.new_timer!
    timer\start time, 0, ->
      timer\stop!
      timer\close!
      uv\stop!

  before_each ->
    dir = "/tmp/spook-spec"
    fs.mkdir_p dir

    dirs = dir_list(dir)
    notifier = spy.new ->
    mapper = spy.new ->
    command = "ls -lah"
    config = {notifier: notifier, mapper: mapper, command: command, watch: dirs}
    spook config

  after_each ->
    fs.rm_rf dir

  describe 'notifications', ->

    it 'gets notified when a new file is added', ->
      file = "#{dirs[1]}/myfile.txt"
      watch_for(1000)
      create_file(500, file)
      uv\run!
      assert.spy(mapper).was_called(1)

