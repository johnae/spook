require "globals"
describe "globals", ->

  it "string.split splits on separator", ->
    str = "a,b,c"
    assert.same {"a","b","c"}, str\split(",")

  it "string.split preserves empty 'items'", ->
    str = "a,b,,c"
    assert.same {"a","b","","c"}, str\split(",")

  it "string.split splits by reserved pattern operator", ->
    str = "a.b..c"
    assert.same {"a","b","","c"}, str\split(".")

  it "string.split splits by character", ->
    str = "abcd"
    assert.same {"a","b","c","d"}, str\split!
    assert.same {"a","b","c","d"}, str\split ''

  it "string.trim removes leading and trailing whitespace", ->
    str1 = " leading"
    str2 = "trailing "
    str3 = " leading and trailing "
    assert.same "leading", str1\trim!
    assert.same "trailing", str2\trim!
    assert.same "leading and trailing", str3\trim!

  it "table.merge merges two tables", ->
    t1 = {a: 1, b: 2}
    t2 = {c: 3, a: 4}
    assert.same {a:4, b:2, c:3}, table.merge(t1, t2)

  it "table.index_of returns the index of value or nil if missing", ->
    t = {"one", "two", "three", "four"}
    assert.equal 3, table.index_of(t, "three")
    assert.nil table.index_of(t, "five")

  it "table.clear clears an indexed table", ->
    t = {"one", "two", "three", "four"}
    table.clear t
    assert.same {}, t

  it "table.clear clears a key/value table", ->
    t = {one: 1, two: 2, three: 3, four: 4}
    table.clear t
    assert.same {}, t

  it "math.round rounds to nearest integer by default", ->
    num = 11.6
    assert.equal 12, math.round(num)

  it "math.round rounds to nearest number by supplied number of decimal digits", ->
    num = 11.667
    assert.equal 11.67, math.round(num, 2)
    assert.equal 11.7, math.round(num, 1)

  describe "getting/changing directory", ->
    local cwd

    before_each ->
      cwd = os.getenv("PWD")

    after_each ->
      chdir(cwd)

    it "getcwd gets the current working directory", ->
      assert.same cwd, getcwd!

    it "chdir changes working directory", ->
      cwd = getcwd!
      chdir("#{cwd}/lib")
      assert.same "#{cwd}/lib", getcwd!

    it "chdir takes a function in which to temporarily change working directory", ->
      cwd = getcwd!
      chdir "#{cwd}/lib", ->
        assert.same "#{cwd}/lib", getcwd!
      assert.same cwd, getcwd!
