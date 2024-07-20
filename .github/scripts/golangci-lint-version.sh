#!/bin/bash
set -euco pipefail

echo "GOLANGCI_LINT_VERSION=$(cat .golangci.version)" >> "$GITHUB_ENV"
