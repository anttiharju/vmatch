#!/usr/bin/env dash
set -eu

echo "GOLANGCI_LINT_VERSION=v$(cat .golangci-version)" >> "$GITHUB_ENV"
