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

# Mimic anttiharju/actions/render-template
set -a
source values.sh
set +a
envsubst < "$formula_file" > formula.rb
