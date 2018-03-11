#!/bin/sh

export DEFAULT_ALWAYS_YES=true
export ASSUME_ALWAYS_YES=true

pkg install tmux
gmake
gmake lint
gmake test