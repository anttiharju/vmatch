#!/usr/bin/env sh
set -eu

BUILD_PREFIX="${BUILD_PREFIX:-sh}"

SHA=$(git rev-parse HEAD)
if [ -n "$(git status --porcelain)" ]; then
  BUILDID="$SHA-dirty"
else
  BUILDID="$SHA"
fi

# build id can be extracted from a binary with
# go tool buildid $APP_NAME
go build -C cmd/"$APP_NAME" -ldflags "-s -w -buildid=$BUILD_PREFIX-$BUILDID -X github.com/anttiharju/vmatch/pkg/exit.appName=$APP_NAME" -o "$(pwd)/$APP_NAME"
