#!/bin/sh

export DEFAULT_ALWAYS_YES=true
export ASSUME_ALWAYS_YES=true

echo --- Install build requirements
pkg install tmux coreutils
echo --- Build spook
gmake
echo +++ Lint
gmake lint
echo +++ Test
gmake test
