config = require "config"
dir_list = require "dir_list"

describe 'config', ->
  local conf

  describe 'default configuration', ->

    before_each ->
      conf = config()!

    it 'has defaults', ->
      expected_watch_dirs = dir_list({"lib", "spec"})
      assert.same expected_watch_dirs, conf.watch
      assert.false conf.show_command
      assert.same require("default_notifier"), conf.notifier
      assert.same "ls", conf.command

  describe 'from Spookfile', ->

    before_each ->
      conf = config!(config_file: 'Spookfile')

    it 'overwrites deafaults with supplied config', ->
      expected_watch_dirs = dir_list({"lib", "spec", "playground"})
      assert.same expected_watch_dirs, conf.watch
      assert.true conf.show_command
      assert.same "./spook -f spec/support/run_busted.lua", conf.command

  describe 'from args', ->
    local args
    before_each ->
      args = {
        watch: {"lib"}
        show_command: true
      }
      conf = config!(args: args)

    it 'overwrites defaults with supplied args', ->
      expected_watch_dirs = dir_list({"lib"})
      assert.same expected_watch_dirs, conf.watch
      assert.true conf.show_command
      assert.same "ls", conf.command -- default
