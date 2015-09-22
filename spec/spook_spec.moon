lfs = require "syscall.lfs"
fs = require "fs"
dir_list = require "dir_list"
spook = require "spook"

describe 'spook', ->
  local dirs, mapper, runner, dir

  create_file = (time, runner, file) ->
    timer = runner.new_timer!
    timer\start time, 0, ->
      f = assert(io.open(file, "w"))
      f\write("hello")
      f\close!
      timer\stop!
      timer\close!

  watch_for = (time, runner) ->
    timer = runner.new_timer!
    timer\start time, 0, ->
      timer\stop!
      timer\close!
      runner\stop!

  before_each ->
    dir = "/tmp/spook-spec"
    fs.mkdir_p dir

    dirs = dir_list({dir})
    notifier = spy.new ->
    mapper = spy.new ->
    runner, watchers = spook(mapper, notifier, {command: {'ls', 'lah'}}, dirs)

  after_each ->
    fs.rm_rf dir

  describe 'notifications', ->

    it 'gets notified when a new file is added', ->
      file = "#{dirs[1]}/myfile.txt"
      watch_for(1000, runner)
      create_file(500, runner, file)
      runner\run!
      assert.spy(mapper).was_called(1)

