Spook = require 'spook'
fs = require 'fs'

describe 'spook', ->
  local spook

  keys = (t) ->
    k = {}
    for key,_ in pairs t
      k[#k + 1] = key
    table.sort k
    k

  before_each ->
    spook = Spook.new!

  count_dirs_in = (dir) ->
    num = 1 -- incoming dir
    for entry, attr in fs.dirtree(dir, true)
      num += 1 if attr.mode == 'directory'
    num

  describe 'call', ->

    describe '#watch', ->

      it 'configures watches via supplied function', ->
        spook ->
          watch 'lib', 'spec', ->
            on_changed "^spec/spec_helper%.moon", -> print "spec_helper"
            on_deleted "^spec/spec_helper%.moon", -> print "spec_helper"
            on_moved "^spec/spec_helper%.moon", -> print "spec_helper"
            on_changed "^lib/something%.moon", -> print "something"

        lib_dir_count = count_dirs_in 'lib'
        spec_dir_count = count_dirs_in 'spec'

        assert.equal lib_dir_count + spec_dir_count, spook.num_dirs
        assert.equal 1, #spook.watches.deleted
        assert.equal 2, #spook.watches.changed
        assert.equal 1, #spook.watches.moved

    describe '#watchnr', ->
      it 'configures non recursive dir watches via supplied function', ->
        spook ->
          watchnr 'lib', 'spec', ->
            on_changed "^spec/spec_helper%.moon", -> print "spec_helper"
            on_deleted "^spec/spec_helper%.moon", -> print "spec_helper"
            on_moved "^spec/spec_helper%.moon", -> print "spec_helper"
            on_changed "^lib/something%.moon", -> print "something"

        assert.equal 2, spook.numnr_dirs
        assert.equal 1, #spook.watches.deleted
        assert.equal 2, #spook.watches.changed
        assert.equal 1, #spook.watches.moved

    it 'configures log_level via supplied function', ->
      spook ->
        log_level 'DEBUG'

      assert.equal 'DEBUG', spook.log_level
