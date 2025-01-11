#!/usr/bin/env dash
set -eu

ROOT=$(pwd)
mkdir -p "$ROOT/bin"
go build \
	-C cmd/vmatch-golangci-lint \
	-ldflags \
	"-s
	-w
	-buildid=
	-X github.com/anttiharju/vmatch-golangci-lint/pkg/exit.appName=$APP_NAME" \
	-o "$ROOT/bin/$APP_NAME"
