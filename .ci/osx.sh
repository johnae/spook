#!/bin/sh

echo --- Install build requirements
brew install tmux sha2
echo --- Build spook
make
echo +++ Lint
make lint
echo +++ Test
make test
