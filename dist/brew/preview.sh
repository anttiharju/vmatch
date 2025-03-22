#!/usr/bin/env bash
set -euo pipefail

# Normalise working directory
cd "$(dirname "${BASH_SOURCE[0]}")"

export GITHUB_REPOSITORY=anttiharju/vmatch

set -a
source values.sh
set +a
envsubst < template.rb > formula.rb
