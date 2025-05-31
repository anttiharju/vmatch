#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

template_file=template.rb
if [[ ! -f "$template_file" ]]; then
  echo "Formula template is missing: $template_file"
  exit 1
fi

# Mock GitHub Actions env
GITHUB_REPOSITORY=anttiharju/vmatch

# Set paths for tag caching
repo_root="$(git rev-parse --show-toplevel)"
tag_cache_file="$repo_root/tag"

# Get the latest version tag from the local git repository
latest_tag="$(git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+' | head -n1)"
if [[ -z "$latest_tag" ]]; then
  echo "No version tags found matching pattern v*.*.*"
  exit 1
fi

# Check if we need to download binaries by comparing cached tag with latest release tag
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
  if [[ "$cached_tag" != "$latest_tag" ]]; then
    echo "New release detected: $latest_tag (was: ${cached_tag:-none})"
    gh release download "$latest_tag" --pattern 'vmatch-*64.tar.gz'
    mv vmatch-*64.tar.gz "$repo_root/"

    # Cache the latest tag
    echo "$latest_tag" > "$tag_cache_file"
  else
    echo "Using cached binaries for tag: $latest_tag"
  fi

  source values.bash | tee "$cache_file"
fi

# Cache file is gitignored and we cannot guarantee its existence
# shellcheck disable=SC1090
source "$cache_file"
set +a

# Template
envsubst < "$template_file" > vmatch.rb

local_tap=false
[[ " $* " =~ " --local-tap " ]] && local_tap=true
if [[ "$local_tap" == true ]]; then
  dir=../../Formula
  mkdir -p "$dir"
  cp vmatch.rb "$dir"
fi

# Easier visual diffing
cp "$template_file" vmatch.template.rb
