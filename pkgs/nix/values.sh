#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${GITHUB_REPOSITORY:-}" ]]; then
  echo "GITHUB_REPOSITORY is not set" >&2
  exit 1
fi

capture() {
  eval "$1=\"$2\""
  echo "$1=\"$2\""
}

repo_name="$(basename "$GITHUB_REPOSITORY")"
echo "REPO_NAME=\"$repo_name\""

capture VERSION "${RENDER_TAG#v}"
capture REPO_OWNER "${GITHUB_REPOSITORY%%/*}"
# hash is handled by CI
