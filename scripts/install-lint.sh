#!/bin/bash
set -euo pipefail

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b . "$VERSION"
