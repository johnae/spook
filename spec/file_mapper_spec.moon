file_mapper = require "file_mapper"

describe 'file_mapper', ->
  local mapping, mapper

  it 'maps a matched file to its specified target', ->
    mapping = {
      "^my/code/(.*)%.moon": (a) -> "my/tests/#{a}_spec.moon"
    }
    mapper = file_mapper(mapping)

    assert.equal "my/tests/awesome_spec.moon", mapper "my/code/awesome.moon"
    assert.equal "my/tests/CODE_HERE_spec.moon", mapper "my/code/CODE_HERE.moon"
    assert.nil mapper "my/unmapped/code.moon"

  it 'takes an array if order is wanted', ->
    mapping = {
      {
        "^some/dir/(.*)%.moon": (a) -> "this/should/#{a}_first.moon"
      }
      {
        "^some/(.*)/(.*)%.moon": (a, b) -> "this/#{a}/#{b}_later.moon"
      }
    }

    mapper = file_mapper(mapping)

    assert.equal "this/should/go_first.moon", mapper "some/dir/go.moon"
    assert.equal "this/should/go_later.moon", mapper "some/should/go.moon"

    assert.nil mapper "my/unmapped/code.moon"
