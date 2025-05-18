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

# Mock what would normally be provided by release job so we can run this locally
TAG="$(basename "$(gh api "repos/$GITHUB_REPOSITORY/releases/latest" --jq .tarball_url)")"

# Cache logic for faster iteration
cache_file=values.cache
quick_mode=false
[[ " $* " =~ " --quick " ]] && quick_mode=true

# Way to render formula with bottles locally
if [[ " $* " =~ " --skip-bottles " ]]; then
    SKIP_BOTTLES=true
else
    version="${TAG#build}"
    if [[ -n $(ls ../../vmatch-"$version".*.tar.gz 2>/dev/null) ]]; then
        echo "Relying on cached bottles"
    else
        rm -rf ../../vmatch-*.bottle.*.tar.gz
        echo "Downloading fresh $TAG bottles"
        gh release download "$TAG" --pattern 'vmatch-*.bottle.*.tar.gz'
        mv vmatch-*.bottle.*.tar.gz ../../
    fi
fi

set -a
if [[ "$quick_mode" == true ]] && [[ -f "$cache_file" ]]; then
    echo "Using cached values from $cache_file"
    cat "$cache_file"
else
    echo "Generating fresh values"
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
