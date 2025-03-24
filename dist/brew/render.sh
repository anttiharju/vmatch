#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

template_file=dist/brew/formula.tpl.rb
if [ ! -f "$template_file" ]; then
    echo "Formula template is missing: $template_file"
    exit 1
fi

# Mock relevant parts of GitHub Actions env
GITHUB_REPOSITORY=anttiharju/vmatch

# Cache logic for faster iteration
cache_file=dist/brew/.values.cache.sh
quick_mode=false
[[ " $* " =~ " --quick " ]] && quick_mode=true

set -a
if [[ "$quick_mode" == true ]] && [[ -f "$cache_file" ]]; then
    echo "Using cached values from $cache_file"
    cat "$cache_file"
else
    echo "Generating fresh values"
    source dist/brew/values.sh | tee "$cache_file"
fi
# Cache file only exists if this script has been ran
# shellcheck disable=SC1090
source "$cache_file"
set +a

# Template
envsubst < "$template_file" > dist/brew/.formula.rb

# Easier diffing
cp "$template_file" dist/brew/.formula.tpl.rb
