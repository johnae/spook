command -v tmux >/dev/null 2>&1 || { echo >&2 "'tmux' is required for these tests. Please install it. Aborting."; exit 1; }

SPOOK=${SPOOK:-"./spook"}
echo "spook command: '$SPOOK'"

nap() {
  sleep 0.55
}

setup() {
  CURRENT_DIR=$(pwd)
  TMPDIR=$(mktemp -d spook-shpec.XXXXXXXXXX)
  TESTDIR=$CURRENT_DIR/$TMPDIR
  mkdir -p $TESTDIR
  LOG=$TESTDIR/log
  echo "" > $LOG
}

teardown() {
  cd $CURRENT_DIR
  if [ "$TMPDIR" != "" ]; then
    rm -rf $TMPDIR
  fi
}

log() {
  cat $LOG | awk 'NF'
}

cleanup() {
    err=$?
    if [ "$spid" != "" ]; then
      kill -INT $spid 2>/dev/null
    fi
    teardown
    trap '' EXIT INT TERM
    exit $err
}

sig_cleanup() {
    trap '' EXIT
    false
    cleanup
}
trap cleanup EXIT
trap sig_cleanup INT QUIT TERM

#### some custom matchers
process_running() {
  ps aux | awk '{for(i=11;i<=NF;i++){printf "%s ", $i}; printf "\n"}' | grep "$1" | grep -v grep > /dev/null 2>&1
  assert equal "$?" 0
}
process_not_running() {
  ps aux | awk '{for(i=11;i<=NF;i++){printf "%s ", $i}; printf "\n"}' | grep "$1" | grep -v grep > /dev/null 2>&1
  assert unequal "$?" 0
}
pid_running() {
  ps -p $1 > /dev/null 2>&1
  assert equal "$?" 0
}
pid_not_running() {
  ps -p $1 > /dev/null 2>&1
  assert unequal "$?" 0
}
####

describe "spook"

  describe "spook (tty mode)"

    it "initial ctrl-c kills only child processes if any are running"
      setup
      mkdir -p $TESTDIR/watchme
      cat<<EOF>$TESTDIR/watchme/slow.sh
#!/bin/sh
echo "\$\$" > $TESTDIR/slowpid
echo "I'm slow"
while true; do
  echo "very slow"
  sleep 1
done
EOF
      chmod +x $TESTDIR/watchme/slow.sh
      cat<<EOF>$TESTDIR/Spookfile
log_level "INFO"
:execute = require "process"
S = require "syscall"
notify = _G.notify
notify.add 'terminal_notifier'
watch "watchme", ->
  on_changed "^watchme/(.*)", (event, name) ->
    execute "watchme/#{name} spook-spec-$$"

pidfile = assert(io.open("pid", "w"))
pidfile\write S.getpid!
pidfile\close!
EOF

    ## because spook requires a tty for this behavior
    ## otherwise it will just exit
    tmux new-session -s spook-shpec-$$ -d
    sleep 5 ## above can be really slow :-/
    tmux send-keys "$SPOOK -w $TESTDIR >> $LOG" Enter; nap
    spid=$(cat $TESTDIR/pid)
    assert pid_running "$spid"

    touch $TESTDIR/watchme/slow.sh ; nap ; nap
    assert file_present $TESTDIR/slowpid
    slowpid=$(cat $TESTDIR/slowpid)
    assert pid_running "$slowpid"

    kill -INT $spid ; nap ; nap
    assert pid_running "$spid"
    assert pid_not_running "$slowpid"

    kill -INT $spid ; nap
    assert pid_not_running "$spid"

    tmux kill-session -t spook-shpec-$$
    teardown
    end
  end

  describe "entr functionality"

    it "executes the given command when any of the given files change"
      setup

      touch $TESTDIR/file
      find $TESTDIR/file -type f | $SPOOK echo {file} changed >>$LOG 2>/dev/null &
      spid=$! ; nap ; nap

      touch $TESTDIR/file ; nap ; nap
      assert equal "$(log)" "$TESTDIR/file changed"

      nap ; echo "content" >> $TESTDIR/file ; nap ; nap
      assert equal "$(log)" "$TESTDIR/file changed\n$TESTDIR/file changed"

      kill -INT $spid 2>/dev/null
      teardown

    end

    describe "-o option"

      it "executes a command just once then exits"
        setup

        touch $TESTDIR/file
        find $TESTDIR/file -type f | $SPOOK -o echo {file} changed >>$LOG 2>/dev/null &
        spid=$!; nap ; nap

        echo "content" >> $TESTDIR/file ; nap
        assert equal "$(log)" "$TESTDIR/file changed"

        nap ; echo "content" >> $TESTDIR/file ; nap
        assert equal "$(log)" "$TESTDIR/file changed" ## no change

        assert equal "$(ps aux | awk '{print $2}' | grep $spid)" ""

        kill -INT $spid 2>/dev/null
        teardown

      end

      it "spook exits with the given commands exit code"
        setup

        cat<<EOF>$TESTDIR/exit_0.sh
#!/bin/sh
exit 0
EOF

        cat<<EOF>$TESTDIR/exit_123.sh
#!/bin/sh
exit 123
EOF
        chmod +x $TESTDIR/exit_*.sh

        ## test 0 exit code
        touch $TESTDIR/file
        find $TESTDIR/file -type f | $SPOOK -o $TESTDIR/exit_0.sh 2>/dev/null &
        spid=$!; nap ; nap

        touch $TESTDIR/file ; nap
        kill -INT $spid 2>/dev/null ## it should be dead already (oneshot) but just in case so we don't hang on wait
        wait $spid
        assert equal "$?" "0"

        ## test 123 exit code
        touch $TESTDIR/file
        find $TESTDIR/file -type f | $SPOOK -o $TESTDIR/exit_123.sh 2>/dev/null &
        spid=$!; nap ; nap

        touch $TESTDIR/file ; nap
        kill -INT $spid 2>/dev/null ## it should be dead already (oneshot) but just in case so we don't hang on wait
        wait $spid
        assert equal "$?" "123"

        teardown

      end

    end

    describe "-s option"

      it "executes persistent command and restarts it when files change"
        setup

        echo "1" > $TESTDIR/instance
        cat<<EOF>$TESTDIR/server.sh
#!/bin/sh
instance=\$(cat $TESTDIR/instance)
echo "Starting server \$instance"
instance=\$((instance+1))
echo "\$instance" > $TESTDIR/instance
while true; do sleep 1; done
EOF
        chmod +x $TESTDIR/server.sh

        touch $TESTDIR/file
        find $TESTDIR/file -type f | $SPOOK -s $TESTDIR/server.sh >>$LOG 2>/dev/null &
        spid=$!; nap ; nap

        assert equal "$(log)" "Starting server 1"
        nap
        echo "stuff" >> $TESTDIR/file ; nap

        assert equal "$(log)" "Starting server 1\nStarting server 2"

        kill -INT $spid 2>/dev/null
        teardown

      end

    end

  end
end
