S = require 'syscall'
Spook = require 'spook'
fs = require 'fs'
remove: pop = table

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

    describe 'fs events', ->
      local dir, subdir, file

      loop = run_loop(require'event_loop'.run_once)

      before_each ->
        dir = "/tmp/spook-fs-events-spec"
        subdir = "#{dir}/subdir"
        file = "#{subdir}/specfile.txt"
        fs.mkdir_p subdir

      after_each ->
        fs.rm_rf dir

      describe 'deleting watched files', ->

        it 'puts a delete event on the internal event stack', ->
          create_file file, "some content"
          spook -> watch dir, ->
          spook\start!
          os.remove file
          loop block_for: 50, loops: 3
          assert.equal 1, #spook.fs_events
          assert.same {
            type: 'fs'
            action: 'deleted'
            path: file
          }, spook.fs_events[1]

      describe 'creating files in a watched directory', ->

        it 'puts a create and a modified event on the internal event stack', ->
          spook -> watch dir, ->
          spook\start!
          create_file file, "some content"
          loop block_for: 50, loops: 3
          assert.equal 2, #spook.fs_events
          assert.same {
            type: 'fs'
            action: 'created'
            path: file
          }, spook.fs_events[1]
          assert.same {
            type: 'fs'
            action: 'modified'
            path: file
          }, spook.fs_events[2]

      describe 'moving files within a watched directory', ->

        it 'puts a move event on the internal event stack', ->
          create_file file, "some content"
          spook -> watch dir, ->
          spook\start!

          S.rename "#{file}", "#{dir}/newname.txt"
          loop block_for: 50, loops: 3
          assert.equal 1, #spook.fs_events
          assert.same {
            type: 'fs'
            action: 'moved'
            path: "#{dir}/newname.txt"
            from: file
            to: "#{dir}/newname.txt"
          }, spook.fs_events[1]

      describe 'watching a single file for changes', ->

        it 'puts the expected events on the internal event stack', ->
          create_file file, "some content"
          spook -> watch_file file, ->
          spook\start!

          f = assert io.open(file, 'a'), "Couldn't open file '#{file}'"
          f\write "content"
          f\close!

          loop block_for: 50, loops: 3
          assert.equal 1, #spook.fs_events
          assert.same {
            type: 'fs'
            action: 'modified'
            path: "#{file}"
          }, spook.fs_events[1]

          pop spook.fs_events

          os.remove file
          loop block_for: 50, loops: 3
          assert.equal 1, #spook.fs_events
          assert.same {
            type: 'fs'
            action: 'deleted'
            path: file
          }, spook.fs_events[1]

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

    it '#one_fs_handler_at_a_time is true by default', ->
      assert.true spook.one_fs_handler_at_a_time

    it 'configures one_fs_handler_at_a_time via supplied function', ->
      spook ->
        one_fs_handler_at_a_time false

      assert.false spook.one_fs_handler_at_a_time
