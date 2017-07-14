command -v tmux >/dev/null 2>&1 || { echo >&2 "'tmux' is required for these tests. Please install it. Aborting."; exit 1; }
echo "tmux version:"
tmux -V

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

## because spook requires a tty for some behavior
## otherwise it will just exit. Here we start a tmux
## session but we don't actually use it. Without
## a session, tmux will just exit. This is here to
## speed up the specs a bit since tmux can be a little
## slow to start. Later we just run new sessions in an
## already running server.
TMUX_SESSION=spook-shpec-session-$$
TMUX="tmux -L $TMUX_SESSION"
echo "tmux: $TMUX"
$TMUX -f /dev/null new-session -s $TMUX_SESSION -d
sleep 6 ## above can be really slow :-/
teardown_tmux() {
  $TMUX kill-session -t $TMUX_SESSION
}

new_tmux_window() {
  window=$($TMUX new-window -P -d)
  sleep 4 ## above can be slow :-/
  echo $window
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
    teardown_tmux
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
  print_result "[ '0' = '$?' ]" "Expected process '$1' to be running"
}
process_not_running() {
  ps aux | awk '{for(i=11;i<=NF;i++){printf "%s ", $i}; printf "\n"}' | grep "$1" | grep -v grep > /dev/null 2>&1
  print_result "[ '0' != '$?' ]" "Expected process '$1' to NOT be running"
}
pid_running() {
  ps -p $1 > /dev/null 2>&1
  print_result "[ '0' = '$?' ]" "Expected process pid '$1' to be running"
}
pid_not_running() {
  ps -p $1 > /dev/null 2>&1
  print_result "[ '0' != '$?' ]" "Expected process pid '$1' NOT to be running"
}
last_log_eq() {
  lines=$(log | tail -$1)
  print_result "[ '$(sanitize "$lines")' = '$(sanitize "$2")' ]" "Expected last $1 log lines to equal:\n\n-----------------------\n$2\n-----------------------\n\nwas\n-----------------------\n$lines\n-----------------------\n\nfull log:\n-----------------------\n$(log)\n-----------------------\n"
}
last_log_not_eq() {
  lines=$(log | tail -$1)
  print_result "[ '$(sanitize "$lines")' != '$(sanitize "$2")' ]" "Expected last $1 log lines to not equal:\n\n-----------------------\n$2\n-----------------------\n\nwas\n-----------------------\n$lines\n-----------------------\n\nfull log:\n-----------------------\n$(log)\n-----------------------\n"
}
####

describe "spook"

  it "puts children in a process group so that grandchildren etc can be controlled"
    setup
    mkdir -p $TESTDIR/watchme
    cat<<EOF>$TESTDIR/watchme/child.sh
#!/bin/sh
echo "\$\$" > $TESTDIR/childpid
echo "I'm a child but I'm also a parent"
$TESTDIR/watchme/grandchild.sh &
while true; do
sleep 1
done
EOF
    chmod +x $TESTDIR/watchme/child.sh

    cat<<EOF>$TESTDIR/watchme/grandchild.sh
#!/bin/sh
echo "\$\$" > $TESTDIR/grandchildpid
echo "I'm a grandchild"
while true; do
sleep 1
done
EOF
    chmod +x $TESTDIR/watchme/grandchild.sh

    cat<<EOF>$TESTDIR/Spookfile
log_level "INFO"
:execute = require "process"
S = require "syscall"
notify.add 'terminal_notifier'
watch "watchme", ->
  on_changed "^watchme/child%.sh", (event) ->
    execute "watchme/child.sh"

pidfile = assert(io.open("pid", "w"))
pidfile\write S.getpid!
pidfile\close!
EOF

    window=$(new_tmux_window)
    $TMUX send-keys -t $window "$SPOOK -w $TESTDIR >> $LOG" Enter; nap ; nap
    spid=$(cat $TESTDIR/pid)
    assert pid_running "$spid"

    touch $TESTDIR/watchme/child.sh ; nap ; nap
    assert file_present $TESTDIR/childpid
    childpid=$(cat $TESTDIR/childpid)
    assert pid_running "$childpid"

    assert file_present $TESTDIR/grandchildpid
    grandchildpid=$(cat $TESTDIR/grandchildpid)
    assert pid_running "$grandchildpid"

    $TMUX send-keys -t $window C-c ; nap ; nap # ctrl-c / SIGINT
    assert pid_running "$spid"
    assert pid_not_running "$childpid"
    assert pid_not_running "$grandchildpid"

    $TMUX send-keys -t $window C-c ; nap ; nap # ctrl-c / SIGINT
    assert pid_not_running "$spid"

    teardown

  end

  it "sets environment variables for the detected change"
    setup
    mkdir -p $TESTDIR/watchme
    cat<<EOF>$TESTDIR/watchme/getenv.sh
#!/bin/sh
echo "SPOOK_CHANGE_PATH: \$SPOOK_CHANGE_PATH" >> $LOG
echo "SPOOK_CHANGE_ACTION: \$SPOOK_CHANGE_ACTION" >> $LOG
echo "SPOOK_MOVED_FROM: \$SPOOK_MOVED_FROM" >> $LOG
EOF
    chmod +x $TESTDIR/watchme/getenv.sh

    cat<<EOF>$TESTDIR/Spookfile
log_level "INFO"
:execute = require "process"
S = require "syscall"
notify.add 'terminal_notifier'
watch "watchme", ->
  on_changed "^watchme/(.*)", (event) ->
    execute "watchme/getenv.sh"

pidfile = assert(io.open("pid", "w"))
pidfile\write S.getpid!
pidfile\close!
EOF

    window=$(new_tmux_window)
    $TMUX send-keys -t $window "$SPOOK -w $TESTDIR" Enter; nap ; nap
    spid=$(cat $TESTDIR/pid)
    assert pid_running "$spid"

    echo "CONTENT" >> $TESTDIR/watchme/newfile ; nap ; nap ; nap
    assert last_log_eq 3 "SPOOK_CHANGE_PATH: watchme/newfile\nSPOOK_CHANGE_ACTION: modified\nSPOOK_MOVED_FROM: "

    mv $TESTDIR/watchme/newfile $TESTDIR/watchme/newname ; nap ; nap ; nap
    assert last_log_eq 3 "SPOOK_CHANGE_PATH: watchme/newname\nSPOOK_CHANGE_ACTION: moved\nSPOOK_MOVED_FROM: watchme/newfile"

    $TMUX send-keys -t $window C-c ; nap # ctrl-c / SIGINT
    assert pid_not_running "$spid"

    teardown

  end

  describe "tty mode / normal mode"

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
notify.add 'terminal_notifier'
watch "watchme", ->
  on_changed "^watchme/(.*)", (event, name) ->
    execute "watchme/#{name}"

pidfile = assert(io.open("pid", "w"))
pidfile\write S.getpid!
pidfile\close!
EOF

      window=$(new_tmux_window)
      $TMUX send-keys -t $window "$SPOOK -w $TESTDIR >> $LOG" Enter; nap
      spid=$(cat $TESTDIR/pid)
      assert pid_running "$spid"

      touch $TESTDIR/watchme/slow.sh ; nap ; nap
      assert file_present $TESTDIR/slowpid
      slowpid=$(cat $TESTDIR/slowpid)
      assert pid_running "$slowpid"

      $TMUX send-keys -t $window C-c ; nap ; nap # ctrl-c / SIGINT
      assert pid_running "$spid"
      assert pid_not_running "$slowpid"

      $TMUX send-keys -t $window C-c ; nap # ctrl-c / SIGINT
      assert pid_not_running "$spid"

      teardown
    end

    it "supports adding a repl"
      setup
      cat<<EOF>$TESTDIR/Spookfile
log_level "INFO"
:execute = require "process"
:repl, :cmdline = require('shell') -> "specrepl>"
S = require "syscall"
notify.add 'terminal_notifier'

cmdline\cmd "mycmd", "Lists things", (screen, value)->
  logfile = assert(io.open("log", "a"))
  for name in *{value, "a","b","c"}
    logfile\write name
  logfile\close!

on_read S.stdin, repl

pidfile = assert(io.open("pid", "w"))
pidfile\write S.getpid!
pidfile\close!
EOF

      window=$(new_tmux_window)
      $TMUX send-keys -t $window "$SPOOK -w $TESTDIR" Enter; nap
      spid=$(cat $TESTDIR/pid)
      assert pid_running "$spid"

      $TMUX send-keys -t $window Enter ; nap
      prompt=$($TMUX capture-pane -t $window -p)
      assert grep "$prompt" "specrepl>"
      $TMUX send-keys -t $window -l "mycmd astring"
      $TMUX send-keys -t $window Enter ; nap

      assert equal "astringabc" "$(log)"

      $TMUX send-keys -t $window Enter ; nap
      $TMUX send-keys -t $window -l "help"
      $TMUX send-keys -t $window Enter ; nap

      helptext=$($TMUX capture-pane -t $window -p)
      assert grep "$helptext" "mycmd"
      assert grep "$helptext" "history"
      assert grep "$helptext" "exit"
      assert grep "$helptext" "\->"

      $TMUX send-keys -t $window C-c ; nap ; nap # ctrl-c / SIGINT
      assert pid_not_running "$spid"

      teardown
    end
  end

  describe "stdin mode / entr mode"

    it "executes the given command when any of the given files change"
      setup

      touch $TESTDIR/file
      find $TESTDIR/file -type f | $SPOOK echo {file} changed >>$LOG 2>/dev/null &
      spid=$! ; nap ; nap

      touch $TESTDIR/file ; nap ; nap
      assert equal "$TESTDIR/file changed" "$(log)"

      nap ; echo "content" >> $TESTDIR/file ; nap ; nap
      assert equal "$TESTDIR/file changed\n$TESTDIR/file changed" "$(log)"

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
        assert equal "$TESTDIR/file changed" "$(log)"

        nap ; echo "content" >> $TESTDIR/file ; nap
        assert equal "$TESTDIR/file changed" "$(log)" ## no change

        assert pid_not_running $spid

        kill -INT $spid 2>/dev/null

        teardown
      end

      it "exits with the given commands exit code"
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
        assert equal "0" "$?"

        ## test 123 exit code
        touch $TESTDIR/file
        find $TESTDIR/file -type f | $SPOOK -o $TESTDIR/exit_123.sh 2>/dev/null &
        spid=$!; nap ; nap

        touch $TESTDIR/file ; nap
        kill -INT $spid 2>/dev/null ## it should be dead already (oneshot) but just in case so we don't hang on wait
        wait $spid
        assert equal "123" "$?"

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

        assert equal "Starting server 1" "$(log)"
        nap
        echo "stuff" >> $TESTDIR/file ; nap

        assert equal "Starting server 1\nStarting server 2" "$(log)"

        kill -INT $spid 2>/dev/null

        teardown

      end

    end

  end

end
