runners = require "runners"

describe "runners", ->

  describe "func", ->
    func = runners.func

    it "calls the function with the specified file", ->
      spy_func = spy.new (file) -> true
      func_runner = func name: "funky", handler: (file) ->
        spy_func file
      run = func_runner "/tmp"
      run!
      assert.spy(spy_func).was_called_with "/tmp"

    it "the runner returns whatever the wrapped function does", ->
      spy_func = spy.new (file) -> true
      func_runner = func name: "funky", handler: (file) ->
        spy_func file
      run = func_runner "/tmp"
      assert.true run!
      spy_func = spy.new (file) -> false
      assert.false run!

  describe "command", ->
    local os_exec, real_exec
    command = runners.command

    before_each ->
      real_exec = os.execute
      os_exec = spy.new -> nil, nil, 0
      os.execute = os_exec

    after_each ->
      os.execute = real_exec

    it "generates command lines", ->
      cmd = command "ls -lah"
      assert.same "ls -lah", cmd![1].name

    it "calls the command with the specified file", ->
      cmd = command "ls -lah"
      run = cmd "/tmp"
      run!
      assert.spy(os_exec).was_called_with "ls -lah /tmp"

    it "by default skips running the command when file does not exist", ->
      cmd = command "ls -lah"
      run = cmd "/tmp/vffhasddiahdgadhgjabsfuahsifadisndjnuqh83283uwg"
      assert.spy(os_exec).was_not_called
      assert.nil run!

    it "expands placeholder for file", ->
      cmd = command "ls -lah [file] | wc -l > [file].count"
      run = cmd "/tmp"
      run!
      assert.spy(os_exec).was_called_with "ls -lah /tmp | wc -l > /tmp.count"

    it "returns true when successful", ->
      cmd = command "ls -lah"
      run = cmd "/tmp"
      success = run!
      assert.true success

    it "returns false when command fails", ->
      os.execute = spy.new -> nil, nil, 1
      cmd = command "echo '[file]'"
      run = cmd "/tmp"
      assert.false run!
