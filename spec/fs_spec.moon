fs = require "fs"
insert = table.insert

describe 'fs', ->

  tmpdir = '/tmp/spook-fs-spec'
  after_each ->
    fs.rm_rf tmpdir

  it 'mkdir_p creates directory structures', ->
    fs.mkdir_p tmpdir .. '/my/dir/structure'
    assert.true fs.is_dir tmpdir .. '/my/dir/structure'

  it 'is_dir returns true for en existing directory and false if not a dir or missing', ->
    assert.false fs.is_dir tmpdir
    fs.mkdir_p tmpdir
    assert.true fs.is_dir tmpdir

  it 'is_file returns true for en existing file and false if not a file or missing', ->
    fs.mkdir_p tmpdir
    assert.false fs.is_file tmpdir
    assert.false fs.is_file tmpdir .. '/myfile.txt'
    f = assert io.open(tmpdir .. '/myfile.txt', "w")
    f\write "hello"
    f\close!
    assert.true fs.is_file tmpdir .. '/myfile.txt'

  it 'is_present returns true for either files or directories', ->
    fs.mkdir_p tmpdir
    f = assert io.open(tmpdir .. '/myfile.txt', "w")
    f\write "hello"
    f\close!
    assert.true fs.is_present tmpdir
    assert.true fs.is_present tmpdir .. '/myfile.txt'

  it 'rm_rf removes directory structures', ->
    fs.mkdir_p tmpdir .. '/my/dir/structure'
    assert.true fs.is_dir tmpdir .. '/my/dir/structure'
    fs.rm_rf tmpdir
    assert.false fs.is_dir tmpdir

  describe 'dirtree', ->

    it 'dirtree by default yields only the contents of specified dir', ->
      fs.mkdir_p tmpdir .. '/my/dir/structure'
      contents = {}
      for entry in fs.dirtree tmpdir
        insert contents, entry
      assert.same {
        tmpdir .. '/my'
      }, contents


    it 'dirtree yields contents of a directory structure recursively when specified', ->
      fs.mkdir_p tmpdir .. '/my/dir/structure'
      f = assert(io.open(tmpdir .. '/my/dir/file.txt', "w"))
      f\write("spec")
      f\close!
      contents = {}
      for entry in fs.dirtree tmpdir, true
        insert contents, entry
      expected = {
        tmpdir .. '/my',
        tmpdir .. '/my/dir',
        tmpdir .. '/my/dir/structure',
        tmpdir .. '/my/dir/file.txt'
      }
      table.sort(expected)
      table.sort(contents)
      assert.same expected, contents

    it 'dirtree yields contents of a directory recursively, ignoring given patterns when specified', ->
      fs.mkdir_p tmpdir .. '/my/dir/structure'
      f = assert(io.open(tmpdir .. '/my/dir/file.txt', "w"))
      f\write("spec")
      f\close!
      f = assert(io.open(tmpdir .. '/my/dir/.hidden.txt', "w"))
      f\write("hidden")
      f\close!
      contents = {}
      for entry in fs.dirtree tmpdir, true
        insert contents, entry
      expected = {
        tmpdir .. '/my',
        tmpdir .. '/my/dir',
        tmpdir .. '/my/dir/structure',
        tmpdir .. '/my/dir/file.txt'
        tmpdir .. '/my/dir/.hidden.txt'
      }
      table.sort(expected)
      table.sort(contents)
      assert.same expected, contents

      contents = {}
      for entry in fs.dirtree tmpdir, recursive: true, ignore: {'^%.hidden%.txt$'}
        insert contents, entry
      expected = {
        tmpdir .. '/my',
        tmpdir .. '/my/dir',
        tmpdir .. '/my/dir/structure',
        tmpdir .. '/my/dir/file.txt'
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

  describe 'unique_subtrees', ->

    it 'descends all given paths and returns unique directories found', ->
      fs.mkdir_p tmpdir .. '/my/dir/a/b/c/a/b/c/d'
      fs.mkdir_p tmpdir .. '/my/dir/a/b/c/b/c/d/e'
      fs.mkdir_p tmpdir .. '/my/dir/a/b/c/c/d/e/f'
      fs.mkdir_p tmpdir .. '/my/dir/a/b/c/d/e/f/g'
      basedir = tmpdir .. '/my/dir'
      trees = fs.unique_subtrees({
        basedir,
        basedir .. '/a/b',
        basedir .. '/a/b/c',
        basedir .. '/a/b/c/a',
        basedir .. '/a/b/c/b',
        basedir .. '/a/b/c/c',
        basedir .. '/a/b/c/d'
      })
      treemap = {name, true for name in *trees}
      unique_trees = [name for name in pairs treemap]
      assert.equal 20, #trees
      assert.equal #unique_trees, #trees