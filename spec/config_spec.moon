config = require "config"
dir_list = require "dir_list"
moon = require "moon"

describe 'config', ->
  local conf

  sorted = (t) ->
    table.sort t
    t

  keys = (t) ->
    k = {}
    for key,_ in pairs t
      k[#k + 1] = key
    sorted k

  describe 'default configuration', ->

    before_each ->
      conf = config()!

    it 'has defaults', ->
      watched = keys(conf.watch)
      assert.same sorted({"lib", "spec"}), watched
      for dir in *watched
        assert.same "ls", conf.watch[dir].command
      assert.false conf.show_command
      assert.same 2, conf.log_level
      assert.same require("default_notifier"), conf.notifier

  describe 'from Spookfile', ->

    before_each ->
      conf = config!(config_file: 'Spookfile')

    it 'overwrites deafaults with supplied config', ->
      watched = keys(conf.watch)
      assert.same sorted({"playground", "lib", "spec"}), watched
      assert.same "./spook -f spec/support/run_busted.lua", conf.watch.lib.command
      assert.same "./spook -f spec/support/run_busted.lua", conf.watch.spec.command
      assert.same "./spook -f", conf.watch.playground.command
      assert.same 2, conf.log_level
      assert.true conf.show_command

  describe 'from args', ->
    local args
    before_each ->
      args = {
        watch: {"spoon"}
        show_command: true
        log_level: 'DEBUG'
      }
      conf = config!(args: args)

    it 'overwrites defaults with supplied args', ->
      watched = keys(conf.watch)
      assert.same {"lib", "spec", "spoon"}, watched
      assert.same 3, conf.log_level
      assert.true conf.show_command
