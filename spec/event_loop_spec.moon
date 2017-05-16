{:Watcher, :Timer, :Signal, :Read, :run_once, :clear_all} = require 'event_loop'
S = require "syscall"
Types = S.t
fs = require "fs"
gettimeofday = gettimeofday

describe 'Event Loop', ->

  loop = run_loop(run_once) -- a spec_helper, see spec/spec_helper.moon

  after_each -> clear_all!

  describe 'Timer', ->

    describe 'state', ->
      local timer

      before_each ->
        timer = Timer.new 0.111, (t) -> nil

      after_each -> loop block_for: 150

      it 'is initially stopped', ->
        assert.true timer.stopped
        assert.false timer.started

      it 'is started after calling #start', ->
        timer\start!
        assert.false timer.stopped
        assert.true timer.started

      it 'is stopped when running the callback', ->
        timer = Timer.new 0.111, (t) ->
          assert.true t.stopped
          assert.false t.started
        timer\start!
        assert.false timer.stopped
        assert.true timer.started

    it 'executes after specified time interval', ->
      local ended
      t = Timer.new 0.111, (t) ->
        ended = gettimeofday!
      started = gettimeofday!
      t\start!
      loop block_for: 150 -- block for a little longer than timer trigger interval
      assert.is.near 111, (ended - started), 30 -- allow +-30ms

    it 'is called once by default', ->
      s = spy.new ->
      t = Timer.new 0.01, (t) ->
        s!
      t\start!
      loop block_for: 25, loops: 2
      assert.spy(s).was.called(1)

    it 'can be rearmed by call to #again', ->
      s = spy.new ->
      t = Timer.new 0.01, (t) ->
        s!
        t\again!
      t\start!
      loop block_for: 25, loops: 2
      assert.spy(s).was.called(2)

    it 'is not called again if stopped even if rearmed', ->
      s = spy.new ->
      t = Timer.new 0.01, (t) ->
        s!
        t\again!
        t\stop!
      t\start!
      loop block_for: 25, loops: 2
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

    describe 'state', ->

      it 'is initially stopped', ->
        w = Watcher.new dir, 'create, delete, move, modify', callback: (w, events) ->
        assert.true w.stopped
        assert.false w.started

      it 'is started after calling #start', ->
        w = Watcher.new dir, 'create, delete, move, modify', callback: (w, events) ->
        w\start!
        assert.false w.stopped
        assert.true w.started

    it 'watches for events in a single directory', ->
      w = Watcher.new dir, 'create, delete, move, modify', callback: (w, events) ->
        event_catcher events

      w\start!
      create_file "#{dir}/testfile.txt", "some content"
      -- this shouldn't be reported - non-recursive
      create_file "#{subdir1}/testfile.txt", "some content"

      loop block_for: 50, loops: 3

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

      loop block_for: 50, loops: 3

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

      loop block_for: 50, loops: 3

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

      loop block_for: 50, loops: 3

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

      loop block_for: 50, loops: 3

      assert.spy(event_catcher).was.called_with {
        {
          from: "#{subdir1}/testfile.txt"
          to: "#{subdir2}/newname.txt"
          path: "#{subdir2}/newname.txt"
          action: 'moved'
        }
      }


  describe 'Signal', ->

    describe 'state', ->
      local s
      before_each ->
        s = Signal.new 'int', (me) -> nil

      after_each ->
        s\stop! unless s.stopped

      it 'is initially stopped', ->
        assert.false s.started
        assert.true s.stopped

      it 'is started after calling #start', ->
        s\start!
        assert.true s.started
        assert.false s.stopped

    describe 'receiving signals', ->
      local shup, spipe, swinch, hup, pipe, winch

      before_each ->
        hup = spy.new ->
        pipe = spy.new ->
        winch = spy.new ->
        shup = Signal.new "hup", hup
        spipe = Signal.new "pipe", pipe
        swinch = Signal.new "winch", winch
        h\start! for h in *{shup, spipe, swinch}


      after_each -> h\stop! for h in *{shup, spipe, swinch}

      it 'receives any given signals sent to process', ->
        S.kill S.getpid!, "hup"
        S.kill S.getpid!, "pipe"

        loop block_for: 50, loops: 2
        assert.spy(hup).was.called(1)
        assert.spy(pipe).was.called(1)
        assert.spy(winch).was.called(0)

      -- this is somewhat "special", at least on bsd (eg. should NOT be ignored on bsd to be received on the queue)
      describe 'sigchld signal', ->
        local schld, chld

        before_each ->
          chld = spy.new ->
          schld = Signal.new 'chld', chld
          schld\start!

        after_each -> schld\stop!

        it 'receives sigchld on child exit', ->
          os.execute "/bin/sleep 0.01"
          loop block_for: 50, loops: 2
          assert.spy(chld).was.called(1)

  describe 'Read', ->
    local socket, msg

    before_each ->
      msg = "Hello from Spook"

      socket = assert S.socket('inet', 'dgram')
      socket\nonblock!
      saddr = assert Types.sockaddr_in(0, 'loopback')
      assert socket\bind(saddr)

    describe 'state', ->
      local r
      before_each ->
        r = Read.new Types.fd(0), (me) -> nil

      it 'is initially stopped', ->
        assert.false r.started
        assert.true r.stopped

      it 'is started after calling #start', ->
        r\start!
        assert.true r.started
        assert.false r.stopped

    it 'notifies with data when given descriptor is readable', ->
      called = 0
      receive = spy.new -> called += 1
      read = Read.new socket, (fd) => receive fd\read!

      read\start!
      addr = assert socket\getsockname!
      csock = assert S.socket('inet', 'dgram')
      csock\sendto msg, #msg, 0, addr

      loop block_for: 50

      assert.spy(receive).was.called_with "Hello from Spook"
      assert.equal 1, called
