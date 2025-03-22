#!/usr/bin/env bash
set -euo pipefail

# Normalise working directory
cd "$(dirname "${BASH_SOURCE[0]}")"

formula_file="formula.tmpl"
if [ ! -f "$formula_file" ]; then
  echo "File not found: $formula_file"
  exit 1
fi

# Mock relevant parts of GitHub Actions env
GITHUB_REPOSITORY="anttiharju/$(basename "$(git rev-parse --show-toplevel)")"

# Cache logic for faster iteration
cache_file=".values.cache"
quick_mode=false
[[ " $* " =~ " --quick " ]] && quick_mode=true

set -a
if [[ "$quick_mode" == true ]] && [[ -f "$cache_file" ]]; then
  echo "Using cached values from $cache_file"
  cat "$cache_file"
else
  echo "Generating fresh values"
  source values.sh | tee "$cache_file"
fi
# Can not assume cache file is always there
# shellcheck disable=SC1090
source "$cache_file"
set +a

# Template
envsubst < "$formula_file" > formula.rb
