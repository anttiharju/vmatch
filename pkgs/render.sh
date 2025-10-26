#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")" # normalize working directory so caller wd does not matter

# Validate pkg_name as enum
pkg_name="${1:-}"
case "$pkg_name" in
  brew|nix)
    ;;
  *)
    echo "Usage: $0 <pkg_name> [--quick] [--local-tap]"
    echo "Valid packages: brew, nix"
    exit 1
    ;;
esac

source github/env_mock.sh

# Paths for source are hardcoded to benefit from shellcheck static analysis
if [[ "$pkg_name" == "brew" ]]; then
  source brew/package.sh
elif [[ "$pkg_name" == "nix" ]]; then
  source nix/package.sh
fi
