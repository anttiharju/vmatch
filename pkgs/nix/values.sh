#!/usr/bin/env bash
set -euo pipefail

capture() {
  eval "export $1=\"$2\""
  echo "export $1=\"$2\""
}

repo_name="$(basename "$GITHUB_REPOSITORY")"
capture PKG_REPO "$repo_name"
capture PKG_VERSION "${TAG#v}"
capture PKLG_OWNER "${GITHUB_REPOSITORY%%/*}"
# HASH is supplied by CI
