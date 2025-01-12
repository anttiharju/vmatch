#!/usr/bin/env sh
set -eu

BUILD_SOURCE="${PREFIX:-sh}"

SHA=$(git rev-parse HEAD)
if [ -n "$(git status --porcelain)" ]; then
  SHA="$SHA-dirty"
fi

BUILD_ID="$BUILD_SOURCE-$SHA"

# build id can be extracted from a binary with
# go tool buildid $APP_NAME
go build -C cmd/"$APP_NAME" -ldflags "-s -w -buildid=$BUILD_ID" -o "$(pwd)/$APP_NAME"
