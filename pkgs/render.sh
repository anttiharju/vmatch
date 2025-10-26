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
cache="$pkg/values.cache"
tag="$(git tag --sort=-creatordate | head -n1)"
export TAG="$tag" # also supplied by CI

# Render
if [[ -f "$cache" && -z "${NO_CACHE:-}" ]]; then
  cat "$cache"
else
  # shellcheck disable=SC1091
  source "$pkg/values.sh" | tee "$cache"
fi

cd "$pkg"
# shellcheck disable=SC1091
source "values.cache"
repository="${GITHUB_REPOSITORY##*/}"
envsubst -i "template.$ext" -no-unset -no-empty > "$repository.$ext"
cp "template.$ext" "$repository.tpl.$ext" # easier to visually diff two gitignored files
