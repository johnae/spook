Spook = require 'spook'
fs = require 'fs'

describe 'spook', ->
  local spook

  before_each ->
    spook = Spook.new!

  count_dirs_in = (dir) ->
    num = 1 -- incoming dir
    for _, attr in fs.dirtree(dir, true)
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

    describe '#watch_file', ->
      it 'configures a single file watch via supplied function', ->
        spook ->
          watch_file 'Spookfile', ->
            on_changed (event) -> print "spec_helper"
            on_deleted (event) -> print "spec_helper"
            on_moved (event) -> print "spec_helper"
            on_changed (event) -> print "something"

        assert.equal 1, spook.file_watches
        assert.equal 1, #spook.watches.deleted
        assert.equal 2, #spook.watches.changed
        assert.equal 1, #spook.watches.moved

    it 'configures log_level via supplied function', ->
      spook ->
        log_level 'DEBUG'

      assert.equal 'DEBUG', spook.log_level

    it '#first_match_only is true by default', ->
      assert.true spook.first_match_only

    it 'configures first_match_only via supplied function', ->
      spook ->
        first_match_only false

      assert.false spook.first_match_only
