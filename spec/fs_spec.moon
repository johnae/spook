fs = require "fs"
insert = table.insert

describe 'fs', ->

  after_each ->
    fs.rm_rf '/tmp/spook-fs-spec'

  it 'mkdir_p creates directory structures', ->
    fs.mkdir_p '/tmp/spook-fs-spec/my/dir/structure'
    assert.true fs.is_dir '/tmp/spook-fs-spec/my/dir/structure'

  it 'is_dir returns true for en existing directory and false if not a dir or missing', ->
    assert.false fs.is_dir '/tmp/spook-fs-spec'
    fs.mkdir_p '/tmp/spook-fs-spec'
    assert.true fs.is_dir '/tmp/spook-fs-spec'

  it 'is_file returns true for en existing file and false if not a file or missing', ->
    fs.mkdir_p '/tmp/spook-fs-spec'
    assert.false fs.is_file '/tmp/spook-fs-spec'
    assert.false fs.is_file '/tmp/spook-fs-spec/myfile.txt'
    f = assert io.open('/tmp/spook-fs-spec/myfile.txt', "w")
    f\write "hello"
    f\close!
    assert.true fs.is_file '/tmp/spook-fs-spec/myfile.txt'

  it 'is_present returns true for either files or directories', ->
    fs.mkdir_p '/tmp/spook-fs-spec'
    f = assert io.open('/tmp/spook-fs-spec/myfile.txt', "w")
    f\write "hello"
    f\close!
    assert.true fs.is_present '/tmp/spook-fs-spec'
    assert.true fs.is_present '/tmp/spook-fs-spec/myfile.txt'

  it 'rm_rf removes directory structures', ->
    fs.mkdir_p '/tmp/spook-fs-spec/my/dir/structure'
    assert.true fs.is_dir '/tmp/spook-fs-spec/my/dir/structure'
    fs.rm_rf '/tmp/spook-fs-spec'
    assert.false fs.is_dir '/tmp/spook-fs-spec'

  describe 'dirtree', ->

    it 'dirtree by default yields only the contents of specified dir', ->
      fs.mkdir_p '/tmp/spook-fs-spec/my/dir/structure'
      contents = {}
      for entry in fs.dirtree '/tmp/spook-fs-spec'
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
      for entry in fs.dirtree '/tmp/spook-fs-spec', true
        insert contents, entry
      expected = {
        '/tmp/spook-fs-spec/my',
        '/tmp/spook-fs-spec/my/dir',
        '/tmp/spook-fs-spec/my/dir/structure',
        '/tmp/spook-fs-spec/my/dir/file.txt'
      }
      table.sort(expected)
      table.sort(contents)
      assert.same expected, contents

  describe 'name_ext', ->

    it 'returns the filename and extension as two parameters', ->
      name, ext = fs.name_ext('my/file.dot.ext')
      assert.equal 'my/file.dot', name
      assert.equal '.ext', ext

    it 'returns the filename and nil when file has no extension', ->
      name, ext = fs.name_ext('my/file')
      assert.equal 'my/file', name
      assert.nil ext

  describe 'basename', ->

    it 'returns the filename without the path', ->
      basename = fs.basename('/path/to/my/file.dot.ext')
      assert.equal 'file.dot.ext', basename
      basename = fs.basename('path/to/my/file.dot.ext')
      assert.equal 'file.dot.ext', basename
      basename = fs.basename('file.dot.ext')
      assert.equal 'file.dot.ext', basename

  describe 'dirname', ->

    it 'returns the directory containing the given path', ->
      dirname = fs.dirname('/path/to/my/file.dot.ext')
      assert.equal '/path/to/my', dirname
      dirname = fs.dirname('path/to/my/file.dot.ext')
      assert.equal 'path/to/my', dirname
      dirname = fs.dirname('/path/to/my/')
      assert.equal '/path/to', dirname
      dirname = fs.dirname('file.dot.ext')
      assert.equal '.', dirname
