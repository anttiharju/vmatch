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

REPO_ROOT="$(git rev-parse --show-toplevel)"
repo_name="$(basename "$GITHUB_REPOSITORY")"

capture class_name "$(awk 'BEGIN{print toupper(substr("'"$repo_name"'",1,1)) substr("'"$repo_name"'",2)}')"
capture description "$(gh repo view --json description --jq .description)"
capture homepage "$(gh api "repos/$GITHUB_REPOSITORY" --jq .homepage)"
capture version "${TAG#v}"
capture darwin_amd64_sha256 "$(sha256 "$REPO_ROOT/vmatch-darwin-amd64.tar.gz" | cut -d= -f2 | tr -d ' ')"
capture darwin_arm64_sha256 "$(sha256 "$REPO_ROOT/vmatch-darwin-arm64.tar.gz" | cut -d= -f2 | tr -d ' ')"
capture linux_amd64_sha256 "$(sha256 "$REPO_ROOT/vmatch-linux-amd64.tar.gz" | cut -d= -f2 | tr -d ' ')"
capture linux_arm64_sha256 "$(sha256 "$REPO_ROOT/vmatch-linux-arm64.tar.gz" | cut -d= -f2 | tr -d ' ')"
