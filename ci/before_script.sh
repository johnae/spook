#!/bin/sh

if [ "$TRAVIS_OS_NAME" = 'linux' ]; then
  add-apt-repository --yes ppa:kalakris/cmake
  apt-get update -qq
  apt-get install cmake
elif [ "$TRAVIS_OS_NAME" = 'osx' ]; then
  brew update
  brew install cmake
else
  echo "Unknown OS: $TRAVIS_OS_NAME"
  exit 1
fi
