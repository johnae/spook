#!/bin/sh

brew install tmux
make
make lint
make test