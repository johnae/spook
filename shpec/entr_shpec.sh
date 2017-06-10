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

teardown() {
  if [ "$TMPDIR" != "" ]; then
    rm -rf $TMPDIR
  fi
}

log() {
  cat $LOG | awk 'NF'
}

describe "spook"
  describe "entr functionality"

    it "executes the given command when any of the given files change"
      setup

      touch $TESTDIR/file
      find $TESTDIR/file -type f | ./spook echo {file} changed >> $LOG 2>/dev/null &
      spid=$! ; nap

      touch $TESTDIR/file ; nap
      assert equal "$(log)" "$TESTDIR/file changed"

      nap; echo "content" >> $TESTDIR/file ; nap
      assert equal "$(log)" "$TESTDIR/file changed\n$TESTDIR/file changed"

      kill -INT $spid 2>/dev/null
      teardown

    end

    it "executes a command just once then exits when given the -o option"
      setup

      touch $TESTDIR/file
      ./spook -o echo {file} changed >> $LOG 2>/dev/null <<< $(find $TESTDIR/file -type f) &
      spid=$!; nap

      echo "content" >> $TESTDIR/file ; nap
      assert equal "$(log)" "$TESTDIR/file changed"

      echo "content" >> $TESTDIR/file ; nap
      assert equal "$(log)" "$TESTDIR/file changed" ## no change

      assert equal "$(ps aux | awk '{print $2}' | grep $spid)" ""

      kill -INT $spid 2>/dev/null
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
      ./spook -s $TESTDIR/server.sh >> $LOG 2>/dev/null <<< $(find $TESTDIR/file -type f) &
      spid=$!; nap

      assert equal "$(log)" "Starting server 1"
      nap
      echo "stuff" >> $TESTDIR/file ; nap

      assert equal "$(log)" "Starting server 1\nStarting server 2"

      kill -INT $spid 2>/dev/null
      teardown

    end

  end
end
