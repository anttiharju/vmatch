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
echo "repo_name=\"$repo_name\""

capture version "${TAG#v}"
capture repo_owner "${GITHUB_REPOSITORY%%/*}"
# hash is handled by CI
