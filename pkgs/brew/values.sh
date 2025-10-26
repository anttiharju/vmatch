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

REPO_ROOT="$(git rev-parse --show-toplevel)"

repo="$(basename "$GITHUB_REPOSITORY")"
capture PKG_REPO "$repo"

class_name="$(awk 'BEGIN{print toupper(substr("'"$repo"'",1,1)) substr("'"$repo"'",2)}')"
capture class_name "$class_name"
description="$(gh repo view --json description --jq .description)"
capture description "$description"
homepage="$(gh api "repos/$GITHUB_REPOSITORY" --jq .homepage)"
capture homepage "$homepage"
capture version "${TAG#v}"
capture repo_owner "${GITHUB_REPOSITORY%%/*}"
darwin_amd64_sha256="$(shasum -a 256 "$REPO_ROOT/$repo-darwin-amd64.tar.gz" | cut -d ' ' -f1)"
capture darwin_amd64_sha256 "$darwin_amd64_sha256"
darwin_arm64_sha256="$(shasum -a 256 "$REPO_ROOT/$repo-darwin-arm64.tar.gz" | cut -d ' ' -f1)"
capture darwin_arm64_sha256 "$darwin_arm64_sha256"
linux_amd64_sha256="$(shasum -a 256 "$REPO_ROOT/$repo-linux-amd64.tar.gz" | cut -d ' ' -f1)"
capture linux_amd64_sha256 "$linux_amd64_sha256"
linux_arm64_sha256="$(shasum -a 256 "$REPO_ROOT/$repo-linux-arm64.tar.gz" | cut -d ' ' -f1)"
capture linux_arm64_sha256 "$linux_arm64_sha256"
