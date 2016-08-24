config = require "config"

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
      assert.same 2, conf.log_level

  describe 'from Spookfile', ->

    before_each ->
      conf = config!(config_file: 'Spookfile')

    it 'overwrites defaults with supplied config', ->
      watched = keys(conf.watch)
      assert.same sorted({"playground", "lib", "spec"}), watched
      assert.same 2, conf.log_level

  describe 'from args', ->
    local args
    before_each ->
      args = log_level: 'DEBUG'
      conf = config!(args: args)

    it 'overwrites defaults with supplied args', ->
      assert.same 3, conf.log_level

    describe 'when Spookfile also sets the value', ->
      before_each ->
        conf = config!(config_file: 'Spookfile', args: {log_level: 'DEBUG'})

      it 'args take precedence', ->
        assert.same 3, conf.log_level
