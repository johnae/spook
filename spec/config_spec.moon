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
      assert.same 2, conf.log_level
      assert.same require("default_notifier"), conf.notifier

  describe 'from Spookfile', ->

    before_each ->
      conf = config!(config_file: 'Spookfile')

    it 'overwrites deafaults with supplied config', ->
      watched = keys(conf.watch)
      assert.same sorted({"playground", "lib", "spec"}), watched
      assert.same 2, conf.log_level

  describe 'from args', ->
    local args
    before_each ->
      args = {
        log_level: 'DEBUG'
      }
      conf = config!(args: args)

    it 'overwrites defaults with supplied args', ->
      assert.same 3, conf.log_level
