#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${GITHUB_REPOSITORY:-}" ]]; then
  echo "GITHUB_REPOSITORY is not set" >&2
  exit 1
fi

capture() {
  eval "export $1=\"$2\""
  echo "export $1=\"$2\""
}

repo_name="$(basename "$GITHUB_REPOSITORY")"
capture REPO_NAME "$repo_name"
capture VERSION "${TAG#v}"
capture REPO_OWNER "${GITHUB_REPOSITORY%%/*}"
# HASH is supplied by CI
