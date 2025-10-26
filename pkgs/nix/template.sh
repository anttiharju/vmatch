#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

if [[ -f "$RENDER_CACHE" && -z "${NO_CACHE:-}" ]]; then
  cat "$RENDER_CACHE"
else
  source values.sh | tee "$RENDER_CACHE"
fi

# shellcheck disable=SC1091
source values.cache

envsubst < "template.nix" > "$PKG_REPO.nix"
cp template.nix "$PKG_REPO.tpl.nix" # for easier visual diffing
