command -v tmux >/dev/null 2>&1 || { echo >&2 "tmux is required for these shpecs. Please install it. Aborting."; exit 1; }

nap() {
  sleep 0.55
}

setup() {
  TMPDIR=$(mktemp -d spook-shpec.XXXXXXXXXX)
  TESTDIR=$TMPDIR/entr
  mkdir -p $TESTDIR
  LOG=$TESTDIR/log
  echo "" > $LOG
}

start_tmux() {
  TSESS=spook-entr-shpec-$$
  tmux new-session -s $TSESS -d
  sleep 5 ## yes, it does take a long time to start - especially in CI
}

teardown() {
  if [ "$TMPDIR" != "" ]; then
    rm -rf $TMPDIR
  fi
  tmux send-keys -t $TSESS:0 C-c || true
}

kill_tmux() {
  tmux send-keys -t $TSESS:0 C-c
  tmux kill-session -t $TSESS
}

cleanup() {
    err=$?
    kill_tmux
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

start_tmux

describe "spook"
  describe "entr functionality"

    it "executes the given command when any of the given files change"
      setup

      touch $TESTDIR/file
      tmux send-keys -t $TSESS:0 "find $TESTDIR/file -type f | ./spook \"echo {file} changed >> $LOG\"" Enter ; nap

      touch $TESTDIR/file ; nap
      assert equal "$(cat $LOG | awk 'NF')" "$TESTDIR/file changed"

      nap; echo "content" >> $TESTDIR/file ; nap
      assert equal "$(cat $LOG | awk 'NF')" "$TESTDIR/file changed\n$TESTDIR/file changed"

      teardown

    end

    it "executes a command just once then exits when given the -o option"
      setup

      touch $TESTDIR/file
      tmux send-keys -t $TSESS:0 "./spook -o \"echo {file} changed >> $LOG\" <<< \$(find $TESTDIR/file -type f)" Enter ; nap

      echo "content" >> $TESTDIR/file ; nap
      assert equal "$(cat $LOG | awk 'NF')" "$TESTDIR/file changed"

      echo "content" >> $TESTDIR/file ; nap
      assert equal "$(cat $LOG | awk 'NF')" "$TESTDIR/file changed" ## no change

      teardown

    end

    it "executes persistent command and restarts it when files change given the -s option"
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
      tmux send-keys -t $TSESS:0 "./spook -s \"$TESTDIR/server.sh >> $LOG\" <<< \$(find $TESTDIR/file -type f)" Enter ; nap

      assert equal "$(cat $LOG | awk 'NF')" "Starting server 1"
      nap
      echo "stuff" >> $TESTDIR/file ; nap

      assert equal "$(cat $LOG | awk 'NF')" "Starting server 1\nStarting server 2"

      teardown

    end

  end
end
