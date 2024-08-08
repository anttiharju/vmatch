#!/bin/sh
set -eu

ROOT=$(pwd)
mkdir -p "$ROOT/bin"
go build \
	-C src \
	-ldflags \
	"-s
	-w
	-buildid=
	-X github.com/anttiharju/vmatch-golangci-lint/src/exit.appName=$APP_NAME" \
	-o "$ROOT/bin/$APP_NAME"
