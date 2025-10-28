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
hash_cache="$pkg.cache"
tag="$(git tag --sort=-creatordate | head -n1)"
tag="${tag:-v0.0.0}"
export TAG="$tag" # also supplied by CI

calculate_hash() {
  local file="$1"
  branch=$(git rev-parse --abbrev-ref HEAD)
  hash=$(shasum -a 256 "$file" | cut -d' ' -f1)
  echo "$branch-$hash"
}

# Check if values.sh changed
if [[ -f "$hash_cache" ]]; then
  current_hash=$(calculate_hash "$pkg/values.sh")
  previous_hash=$(cat "$hash_cache")
  [[ "$current_hash" != "$previous_hash" ]] && export NO_CACHE=1
else
  export NO_CACHE=1
fi

# Render
calculate_hash "$pkg/values.sh" > "$hash_cache"
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
filename="${repository//-/_}"
envsubst -i "template.$ext" -no-unset -no-empty > "$filename.$ext"
cp "template.$ext" "$filename.tpl.$ext" # easier to visually diff two gitignored files
