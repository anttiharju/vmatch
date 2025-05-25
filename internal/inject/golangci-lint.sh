#!/usr/bin/env sh

if [ -t 1 ]; then
  colors=true
fi

VMATCH_GOLANGCI_LINT_COLORS=$colors vmatch golangci-lint "$@"
