#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")" # normalize working directory so caller wd does not matter

# Validate PKG as enum
PKG="${1:-}"
case "$PKG" in
  brew|nix)
    ;;
  *)
    echo "Usage: $0 <PKG> [--quick] [--local-tap]"
    echo "Valid packages: brew, nix"
    exit 1
    ;;
esac

source github/env_mock.sh

# Paths for source are hardcoded to benefit from shellcheck static analysis
if [[ "$PKG" == "brew" ]]; then
  source brew/package.sh
elif [[ "$PKG" == "nix" ]]; then
  source nix/package.sh
fi
