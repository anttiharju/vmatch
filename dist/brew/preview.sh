#!/usr/bin/env bash
set -euo pipefail

# Normalise working directory
cd "$(dirname "${BASH_SOURCE[0]}")"

# Mock relevant parts of GitHub Actions env
GITHUB_REPOSITORY="anttiharju/$(basename "$(git rev-parse --show-toplevel)")"

# Mimic anttiharju/actions/render-template
set -a
source values.sh
set +a
envsubst < formula.tmpl.rb > formula.rb
