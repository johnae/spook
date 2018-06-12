#!/bin/sh

set -x

URL=$1
OUT=$2

if command -v wget >/dev/null 2>&1; then
    DOWNLOAD="wget -O"
elif command -v curl >/dev/null 2>&1; then
    DOWNLOAD="curl -L -o"
else
    echo "Neither wget nor curl are available, please install one of them."
    exit 1
fi

if command -v sha256sum > /dev/null 2>&1; then
    fileHash()  {
        sha256sum -b "$1" | cut -c1-64
    }
elif command -v shasum > /dev/null 2>&1; then
    fileHash()  {
        shasum -a 256 -b "$1" | cut -c1-64
    }
elif command -v openssl > /dev/null 2>&1; then
    fileHash()  {
        openssl dgst -r -sha256 "$1" | cut -c1-64
    }
else
    echo "Sorry, couldn't find 'sha256sum', 'shasum' or 'openssl' - I need one of them to verify '$OUT'"
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
    echo "Downloading '$URL' to '$OUT'..."
    $DOWNLOAD $OUT $URL
else
    echo "$OUT already present, skipping download"
fi

DIR=$(dirname $OUT)
NAME=$(basename $OUT)
cd $DIR
expected_sha_sum=$(cat $NAME.sha256 | cut -c1-64)
actual_sha_sum=$(fileHash $NAME)
if [ "$expected_sha_sum" != "$actual_sha_sum" ]; then
    echo "Expected checksum of file $NAME to be '$expected_sha_sum', was '$actual_sha_sum'"
    mv $OUT $OUT.bad_sha256
    exit 1
fi