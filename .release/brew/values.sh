#!/usr/bin/env bash
set -euo pipefail

capture() {
  eval "export $1=\"$2\""
  echo "export $1=\"$2\""
}

repo="$(basename "$GITHUB_REPOSITORY")"
capture PKG_REPO "$repo"
class="$(echo "$repo" | awk -F'-' '{for(i=1;i<=NF;i++) printf "%s%s", toupper(substr($i,1,1)), substr($i,2)}')"
capture PKG_CLASS "$class"
desc="$(gh repo view --json description --jq .description)"
capture PKG_DESC "$desc"
homepage="$(gh api "repos/$GITHUB_REPOSITORY" --jq .homepage)"
capture PKG_HOMEPAGE "$homepage/"
capture PKG_VERSION "${TAG#v}"
capture PKG_OWNER "${GITHUB_REPOSITORY%%/*}"

if [[ "$TAG" = "v0.0.0" ]]; then
  capture PKG_MAC_INTEL_SHA TBD
  capture PKG_MAC_ARM_SHA TBD
  capture PKG_LINUX_INTEL_SHA TBD
  capture PKG_LINUX_ARM_SHA TBD
  exit 0
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"
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
