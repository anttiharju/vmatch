#!/usr/bin/env bash
set -euo pipefail

# Normalise working directory
cd "$(dirname "${BASH_SOURCE[0]}")"

formula_file="template.rb"
if [ ! -f "$formula_file" ]; then
    echo "Template file is missing: $formula_file"
    exit 1
fi

# Mock relevant parts of GitHub Actions env
GITHUB_REPOSITORY="anttiharju/$(basename "$(git rev-parse --show-toplevel)")"

# Cache logic for faster iteration
cache_file=".values.cache.sh"
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
# Cache file only exists if this script has been ran
# shellcheck disable=SC1090
source "$cache_file"
set +a

# Template
envsubst < "$formula_file" > formula.rb

# Easier diffing
cp template.rb formula.tpl.rb
