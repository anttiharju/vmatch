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

cache_file=".values.cache"
quick_mode=false
[[ " $* " =~ " --quick " ]] && quick_mode=true
if [[ "$quick_mode" == true ]] && [[ -f "$cache_file" ]]; then
  echo "Using cached values from $cache_file"
  set -a
  # cache file does not always exist
  # shellcheck disable=SC1090
  source "$cache_file"
  cat "$cache_file"
  set +a
else
  echo "Generating fresh values"
  set -a
  source values.sh | tee "$cache_file"
  # cache file does not always exist
  # shellcheck disable=SC1090
  source "$cache_file"
  set +a
fi

envsubst < "$formula_file" > formula.rb
