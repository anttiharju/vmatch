#!/usr/bin/env bash
set -euo pipefail

capture() {
  eval "export $1=\"$2\""
  echo "export $1=\"$2\""
}

repo_name="$(basename "$GITHUB_REPOSITORY")"
capture REPO_NAME "$repo_name"
capture VERSION "${TAG#v}"
capture REPO_OWNER "${GITHUB_REPOSITORY%%/*}"
# HASH is supplied by CI
