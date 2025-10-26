#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")" # normalize working directory so caller wd does not matter

# Validate pkg as enum
pkg="${1:-}"
case "$pkg" in
  brew)
    ext="rb"
    ;;
  nix)
    ext="nix"
    ;;
  *)
    echo "Usage: $0 <package> [--no-cache]"
    echo "Valid packages: brew, nix"
    exit 1
    ;;
esac

# Parse flags
[[ " $* " =~ " --no-cache " ]] && export NO_CACHE=1

# Setup env
source github/actions_env_mock.sh
cache="values.cache"
tag="$(git tag --sort=-creatordate | head -n1)"
export TAG="$tag" # also supplied by CI

# Render
cd "$pkg"
if [[ -f "$cache" && -z "${NO_CACHE:-}" ]]; then
  cat "$cache"
else
  # shellcheck disable=SC1091
  source "values.sh" | tee "$cache"
fi

# shellcheck disable=SC1091
source "values.cache"
envsubst < "template.$ext" > "$PKG_REPO.$ext"
cp "template.$ext" "$PKG_REPO.tpl.$ext" # easier to visually diff two gitignored files
