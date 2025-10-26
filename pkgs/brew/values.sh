#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

capture() {
  eval "export $1=\"$2\""
  echo "export $1=\"$2\""
}

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

pattern="$repo-*64.tar.gz"
gh release download "$TAG" --pattern "$pattern" --clobber
for binary in $pattern; do
  echo "# $binary"
done
darwin_amd64_sha256="$(shasum -a 256 "$repo-darwin-amd64.tar.gz" | cut -d ' ' -f1)"
capture darwin_amd64_sha256 "$darwin_amd64_sha256"
darwin_arm64_sha256="$(shasum -a 256 "$repo-darwin-arm64.tar.gz" | cut -d ' ' -f1)"
capture darwin_arm64_sha256 "$darwin_arm64_sha256"
linux_amd64_sha256="$(shasum -a 256 "$repo-linux-amd64.tar.gz" | cut -d ' ' -f1)"
capture linux_amd64_sha256 "$linux_amd64_sha256"
linux_arm64_sha256="$(shasum -a 256 "$repo-linux-arm64.tar.gz" | cut -d ' ' -f1)"
capture linux_arm64_sha256 "$linux_arm64_sha256"
