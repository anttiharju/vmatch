#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

if [[ ! -f "$RENDER_CACHE" ]]; then
  source values.sh | tee "$RENDER_CACHE"
fi

# shellcheck disable=SC1091
source values.cache

envsubst < "template.nix" > ".template.nix"
