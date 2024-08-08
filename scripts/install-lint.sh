#!/bin/sh
set -eu

if [ -f "$INSTALL_DIR/golangci-lint" ]; then
  # golangci-lint already installed
  exit 0
fi

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b . v"$VERSION"
