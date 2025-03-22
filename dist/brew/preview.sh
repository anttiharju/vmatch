#!/usr/bin/env bash
set -euo pipefail

# Normalise working directory
cd "$(dirname "${BASH_SOURCE[0]}")"

# Match what is used from GitHub Actions env
export GITHUB_REPOSITORY="anttiharju/vmatch"

# Mimic anttiharju/actions/render-template
set -a
source values.sh
set +a
envsubst < template.rb > formula.rb
