#!/bin/sh
set -e
echo --- Install build requirements
apt-get update -yqqu
apt-get install -yqq tmux build-essential git
echo --- Build spook
make
echo +++ Lint
make lint
echo +++ Test
make test
kill -s INT $BUILDKITE_AGENT_PID