#!/bin/sh

echo --- Install build requirements
brew install tmux
echo --- Build spook
make
echo +++ Lint
make lint
echo +++ Test
make test