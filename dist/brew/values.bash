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

capture class_name "$(awk 'BEGIN{print toupper(substr("'"$repo_name"'",1,1)) substr("'"$repo_name"'",2)}')"
capture description "$(gh repo view --json description --jq .description)"
capture homepage "$(gh api "repos/$GITHUB_REPOSITORY" --jq .homepage)"
capture version "${TAG#v}"
capture darwin_amd64_sha256 "1"
capture darwin_arm64_sha256 "2"
capture linux_amd64_sha256 "3"
capture linux_arm64_sha256 "4"
