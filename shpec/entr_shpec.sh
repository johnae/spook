SPOOK=${SPOOK:-"./spook"}

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

describe "spook"
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
