#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

template_file=template.rb
if [[ ! -f "$template_file" ]]; then
  echo "Formula template is missing: $template_file"
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
repo_name="$(basename "$repo_root")"

# Mock GitHub Actions env
GITHUB_REPOSITORY="anttiharju/$repo_name"
TAG="$(git tag --sort=-creatordate | head -n1)"

# Check if we need to download binaries by comparing cached tag with latest release tag
tag_cache_file="$repo_root/tag"
cached_tag=""
[[ -f "$tag_cache_file" ]] && cached_tag="$(cat "$tag_cache_file")"

# Cache logic for faster template iteration
cache_file=values.cache
quick_mode=false
[[ " $* " =~ " --quick " ]] && quick_mode=true

set -a
if [[ "$quick_mode" == true ]] && [[ -f "$cache_file" ]]; then
  echo "Using cached values from $cache_file"
  cat "$cache_file"
else
  echo "Generating fresh values"

  # Only download binaries if the tag has changed or cache doesn't exist
  if [[ "$cached_tag" != "$TAG" ]]; then
    echo "New release detected: $TAG (was: ${cached_tag:-none})"
    gh release download --pattern "$repo_name-*64.tar.gz"
    find . -name "$repo_name-*64.tar.gz" -exec mv {} "$repo_root/" \;

    # Cache the latest tag
    echo "$TAG" > "$tag_cache_file"
  else
    echo "Using cached binaries for tag: $TAG"
  fi

  source values.bash | tee "$cache_file"
fi

# Cache file is gitignored and we cannot guarantee its existence
# shellcheck disable=SC1090
source "$cache_file"
set +a

# Template
envsubst < "$template_file" > ".$repo_name.rb"

local_tap=false
[[ " $* " =~ " --local-tap " ]] && local_tap=true
if [[ "$local_tap" == true ]]; then
  dir="$repo_root/Formula"
  mkdir -p "$dir"
  cp ".$repo_name.rb" "$dir"
fi

# Easier visual diffing
cp "$template_file" ".$repo_name.template.rb"
