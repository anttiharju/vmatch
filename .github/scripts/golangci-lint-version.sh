#!/bin/bash
set -euo pipefail

echo "GOLANGCI_LINT_VERSION=$(cat .golangci.version)" >> "$GITHUB_ENV"
