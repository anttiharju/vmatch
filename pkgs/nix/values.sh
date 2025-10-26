#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

capture() {
  eval "export $1=\"$2\""
  echo "export $1=\"$2\""
}

repo="$(basename "$GITHUB_REPOSITORY")"
capture PKG_REPO "$repo"
capture PKG_VERSION "${TAG#v}"
capture PKG_OWNER "${GITHUB_REPOSITORY%%/*}"
rev="$(gh api "repos/$GITHUB_REPOSITORY/git/ref/tags/$TAG" --jq '.object.sha')"
capture PKG_REV "$rev"
sha256="$(nix-prefetch-url --quiet --unpack "https://github.com/$GITHUB_REPOSITORY/archive/$rev.tar.gz")"
hash="$(nix hash convert --hash-algo sha256 --to sri "$sha256")"
capture PKG_HASH "$hash"
