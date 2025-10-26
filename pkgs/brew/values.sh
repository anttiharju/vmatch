#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

capture() {
  eval "export $1=\"$2\""
  echo "export $1=\"$2\""
}

repo="$(basename "$GITHUB_REPOSITORY")"
capture PKG_REPO "$repo"
class="$(awk 'BEGIN{print toupper(substr("'"$repo"'",1,1)) substr("'"$repo"'",2)}')"
capture PKG_CLASS "$class"
desc="$(gh repo view --json description --jq .description)"
capture PKG_DESC "$desc"
homepage="$(gh api "repos/$GITHUB_REPOSITORY" --jq .homepage)"
capture PKG_HOMEPAGE "$homepage"
capture PKG_VERSION "${TAG#v}"
capture PKG_OWNER "${GITHUB_REPOSITORY%%/*}"

pattern="$repo-*64.tar.gz"
gh release download "$TAG" --pattern "$pattern" --clobber
for binary in $pattern; do
  echo "# $binary"
done
mac_intel_sha="$(shasum -a 256 "$repo-darwin-amd64.tar.gz" | cut -d ' ' -f1)"
capture PKG_MAC_INTEL_SHA "$mac_intel_sha"
mac_arm_sha="$(shasum -a 256 "$repo-darwin-arm64.tar.gz" | cut -d ' ' -f1)"
capture PKG_MAC_ARM_SHA "$mac_arm_sha"
linux_intel_sha="$(shasum -a 256 "$repo-linux-amd64.tar.gz" | cut -d ' ' -f1)"
capture PKG_LINUX_INTEL_SHA "$linux_intel_sha"
linux_arm_sha="$(shasum -a 256 "$repo-linux-arm64.tar.gz" | cut -d ' ' -f1)"
capture PKG_LINUX_ARM_SHA "$linux_arm_sha"
