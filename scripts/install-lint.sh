#!/usr/bin/env bash

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b . "$VERSION"
