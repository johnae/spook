file_mapper = require "file_mapper"

describe 'file_mapper', ->
  local mapping, mapper

  it 'maps a matched file to its specified target', ->
    mapping = {{"^my/code/(.*)%.moon", (a) -> "my/tests/#{a}_spec.moon"}}
    mapper = file_mapper(mapping)

    assert.equal "my/tests/awesome_spec.moon", mapper "my/code/awesome.moon"
    assert.equal "my/tests/CODE_HERE_spec.moon", mapper "my/code/CODE_HERE.moon"
    assert.nil mapper "my/unmapped/code.moon"

