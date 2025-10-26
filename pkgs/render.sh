#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")" # normalize working directory so caller wd does not matter

# Validate PKG as enum
pkg="${1:-}"
case "$pkg" in
  brew|nix)
    ;;
  *)
    echo "Usage: $0 <PKG> [--quick] [--local-tap]"
    echo "Valid packages: brew, nix"
    exit 1
    ;;
esac

# Parse optional flags
shift
for arg in "$@"; do
  case "$arg" in
    --no-cache)
      export NO_CACHE=1
      ;;
  esac
done

RENDER_CACHE=values.cache
TAG="$(git tag --sort=-creatordate | head -n1)" # also supplied by CI

source github/env_mock.sh

# Paths for source are hardcoded to benefit from shellcheck static analysis
if [[ "$pkg" == "brew" ]]; then
  source brew/package.sh
elif [[ "$pkg" == "nix" ]]; then
  source nix/template.sh
fi
