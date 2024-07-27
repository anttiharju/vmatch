#!/bin/sh
set -eu

echo "GOLANGCI_LINT_VERSION=$(cat .golangci-version)" >> "$GITHUB_ENV"
