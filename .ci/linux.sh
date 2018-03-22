#!/bin/sh
set -e
apt-get update -yqqu
apt-get install -yqq tmux build-essential git
make
make lint
make test
kill -s INT $BUILDKITE_AGENT_PID
