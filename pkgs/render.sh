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

tag="$(git tag --sort=-creatordate | head -n1)"
export TAG="$tag" # also supplied by CI
export RENDER_CACHE="values.cache"

source github/actions_env_mock.sh

# Paths for source are hardcoded to benefit from shellcheck static analysis
if [[ "$pkg" == "brew" ]]; then
  source brew/template.sh
  ext="rb"
elif [[ "$pkg" == "nix" ]]; then
  source nix/template.sh
  ext="nix"
fi

envsubst < "template.$ext" > "$PKG_REPO.$ext"
cp "template.$ext" "$PKG_REPO.tpl.$ext" # for easier visual diffing
