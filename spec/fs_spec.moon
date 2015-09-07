lfs = require "syscall.lfs"
fs = require "fs"
insert = table.insert

describe 'fs', ->

  after_each ->
    fs.rm_rf '/tmp/spook-fs-spec'

  it 'mkdir_p creates directory structures', ->
    fs.mkdir_p '/tmp/spook-fs-spec/my/dir/structure'
    assert.true fs.is_dir '/tmp/spook-fs-spec/my/dir/structure'

  it 'rm_rf removes directory structures', ->
    fs.mkdir_p '/tmp/spook-fs-spec/my/dir/structure'
    assert.true fs.is_dir '/tmp/spook-fs-spec/my/dir/structure'
    fs.rm_rf '/tmp/spook-fs-spec'
    assert.false fs.is_dir '/tmp/spook-fs-spec'

  describe 'dirtree', ->

    it 'dirtree by default yields only the contents of specified dir', ->
      fs.mkdir_p '/tmp/spook-fs-spec/my/dir/structure'
      contents = {}
      for entry, attr in fs.dirtree '/tmp/spook-fs-spec'
        insert contents, entry
      assert.same {
        '/tmp/spook-fs-spec/my'
      }, contents


    it 'dirtree yields contents of a directory structure recursively when specified', ->
      fs.mkdir_p '/tmp/spook-fs-spec/my/dir/structure'
      f = assert(io.open('/tmp/spook-fs-spec/my/dir/file.txt', "w"))
      f\write("spec")
      f\close!
      contents = {}
      for entry, attr in fs.dirtree '/tmp/spook-fs-spec', true
        insert contents, entry
      assert.same {
        '/tmp/spook-fs-spec/my',
        '/tmp/spook-fs-spec/my/dir',
        '/tmp/spook-fs-spec/my/dir/structure',
        '/tmp/spook-fs-spec/my/dir/file.txt'
      }, contents