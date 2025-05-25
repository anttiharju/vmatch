#!/usr/bin/env sh

if [ -t 1 ]; then
  colors=true
fi

TERMINAL=$colors /Users/antti/anttiharju/vmatch/vmatch golangci-lint "$@"
