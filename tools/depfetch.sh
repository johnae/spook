#!/bin/sh

URL=$1
OUT=$2

if command -v wget >/dev/null 2>&1; then
    DOWNLOAD="wget -q -O"
elif command -v curl >/dev/null 2>&1; then
    DOWNLOAD="curl -s -L -o"
else
    echo "Neither wget nor curl are available, please install one of them."
    exit 1
fi

if ! command -v sha256sum >/dev/null 2>&1; then
    echo "Please install sha256sum."
    exit 1
fi

if [ -z "$URL" ]; then
    echo "Missing url: '$URL'"
    exit 1
fi

if [ -z "$OUT " ]; then
    echo "Missing out: '$OUT'"
    exit 1
fi

if [ ! -e $OUT ]; then
    $DOWNLOAD $OUT $URL
else
    echo "$OUT already present, skipping download"
fi

DIR=$(dirname $OUT)
NAME=$(basename $OUT)
cd $DIR
if ! sha256sum -c $NAME.sha256 > /dev/null; then
    echo "Bad SHA256 sum on $OUT, moving $OUT to $OUT.bad_sha256"
    mv $OUT $OUT.bad_sha256
    exit 1
fi