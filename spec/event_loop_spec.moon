{:Watcher, :Timer, :Signal, :Read, :run_once, :clear_all} = require 'event_loop'
S = require "syscall"
Types = S.t
fs = require "fs"
gettimeofday = gettimeofday

describe 'Event Loop', ->

  after_each -> clear_all!

  describe 'Timer', ->

    it 'executes after specified time interval', ->
      local ended
      t = Timer.new 0.111, (t) ->
        ended = gettimeofday!
      started = gettimeofday!
      t\start!
      run_once block_for: 150 -- block for a little longer than timer trigger interval
      assert.is.near 111, (ended - started), 12 -- allow +-12ms

    it 'is called once by default', ->
      s = spy.new ->
      t = Timer.new 0.01, (t) ->
        s!
      t\start!
      run_once block_for: 25
      run_once block_for: 25
      assert.spy(s).was.called(1)

    it 'can be rearmed by call to #again', ->
      s = spy.new ->
      t = Timer.new 0.01, (t) ->
        s!
        t\again!
      t\start!
      run_once block_for: 25
      run_once block_for: 25
      assert.spy(s).was.called(2)

    it 'is not called again if stopped even if rearmed', ->
      s = spy.new ->
      t = Timer.new 0.01, (t) ->
        s!
        t\again!
        t\stop!
      t\start!
      run_once block_for: 25
      run_once block_for: 25
      assert.spy(s).was.called(1)

  describe 'Watcher', ->
    local dir, subdir1, subdir2, event_catcher

    before_each ->
      dir = "/tmp/spook-watcher-spec"
      subdir1 = "/tmp/spook-watcher-spec/a"
      subdir2 = "/tmp/spook-watcher-spec/a/b"
      fs.mkdir_p subdir2
      event_catcher = spy.new (events) ->

    after_each ->
      fs.rm_rf dir

    it 'watches for events in a single directory', ->
      w = Watcher.new dir, 'create, delete, move, modify', callback: (w, events) ->
        event_catcher events

      w\start!
      create_file "#{dir}/testfile.txt", "some content"
      -- this shouldn't be reported - non-recursive
      create_file "#{subdir1}/testfile.txt", "some content"
      run_once block_for: 50

      assert.spy(event_catcher).was.called_with {
        {
          path: "#{dir}/testfile.txt"
          action: 'created'
        },
        {
          path: "#{dir}/testfile.txt"
          action: 'modified'
        }
      }

      os.remove "#{dir}/testfile.txt"
      -- this shouldn't be reported - non-recursive
      os.remove "#{subdir1}/testfile.txt"
      run_once block_for: 50

      assert.spy(event_catcher).was.called_with {
        {
          path: "#{dir}/testfile.txt"
          action: 'deleted'
        }
      }

    it 'watches for events recursively in a directory', ->
      w = Watcher.new dir, 'create, delete, move, modify', recursive: true, callback: (w, events) ->
        event_catcher events

      w\start!

      create_file "#{subdir1}/testfile.txt", "some content"
      run_once block_for: 50
      assert.spy(event_catcher).was.called_with {
        {
          path: "#{subdir1}/testfile.txt"
          action: 'created'
        },
        {
          path: "#{subdir1}/testfile.txt"
          action: 'modified'
        }
      }
      create_file "#{subdir2}/testfile.txt", "some content"
      run_once block_for: 50
      assert.spy(event_catcher).was.called_with {
        {
          path: "#{subdir2}/testfile.txt"
          action: 'created'
        },
        {
          path: "#{subdir2}/testfile.txt"
          action: 'modified'
        }
      }

    it 'detects file moves', ->
      w = Watcher.new dir, 'create, delete, move, modify', recursive: true, callback: (w, events) ->
        event_catcher events

      create_file "#{subdir1}/testfile.txt", "some content"
      w\start!

      S.rename "#{subdir1}/testfile.txt", "#{subdir2}/newname.txt"
      run_once block_for: 50
      assert.spy(event_catcher).was.called_with {
        {
          from: "#{subdir1}/testfile.txt"
          to: "#{subdir2}/newname.txt"
          path: "#{subdir2}/newname.txt"
          action: 'moved'
        }
      }


  describe 'Signal', ->

    it 'receives any given signals sent to process', ->
      local received_hup, received_pipe, received_winch
      shup = Signal.new "hup", (me) -> received_hup = true
      spipe = Signal.new "pipe", (me) -> received_pipe = true
      swinch = Signal.new "winch", (me) -> received_winch = true
      shup\start!
      spipe\start!
      swinch\start!
      S.kill S.getpid!, "hup"
      S.kill S.getpid!, "pipe"
      for i=1,2
        run_once block_for: 50
      assert.true received_hup
      assert.true received_pipe
      assert.nil received_winch

  describe 'Read', ->
    local socket, msg

    before_each ->
      msg = "Hello from Spook"

      socket = assert S.socket('inet', 'dgram')
      socket\nonblock!
      saddr = assert Types.sockaddr_in(0, 'loopback')
      assert socket\bind(saddr)

    it 'notifies with data when given descriptor is readable', ->
      local received
      read = Read.new socket, (data) =>
        received = data

      read\start!
      addr = assert socket\getsockname!
      csock = assert S.socket('inet', 'dgram')
      csock\sendto msg, #msg, 0, addr
      run_once block_for: 50
      assert.equal "Hello from Spook", received
