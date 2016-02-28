file_mapper = require "file_mapper"
{:command} = require "runners"

describe 'file_mapper', ->
  local mapping, mapper, os_exec, real_exec

  before_each ->
    real_exec = os.execute
    os_exec = spy.new -> true
    os.execute = os_exec

  after_each ->
    os.execute = real_exec

  it 'maps a matched file to its specified target runnable', ->

    cmd = command "test", only_if: -> true
    cmd2 = command "test2", only_if: -> true

    mapping = {
      {"^my/code/(.*)%.moon", (a) -> cmd "my/tests/#{a}_spec.moon"}
      {"^my/other/code/(.*)%.moon", (a) -> cmd2 "my/other/tests/#{a}_spec.moon"}
    }
    mapper = file_mapper(mapping)
    
    run = mapper("my/code/awesome.moon")!
    run "my/code/something.moon"
    assert.spy(os_exec).was.called_with "test my/tests/awesome_spec.moon"

    run = mapper("my/other/code/CODE_HERE.moon")!
    run!
    assert.spy(os_exec).was.called_with "test2 my/other/tests/CODE_HERE_spec.moon"

    run = mapper "my/unmapped/code.moon"
    assert.nil run
