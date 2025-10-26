#!/usr/bin/env bash
set -euo pipefail

capture() {
  eval "export $1=\"$2\""
  echo "export $1=\"$2\""
}

repo_name="$(basename "$GITHUB_REPOSITORY")"
capture PKG_REPO "$repo_name"
capture PKG_VERSION "${TAG#v}"
capture PKG_OWNER "${GITHUB_REPOSITORY%%/*}"
pkg_rev="$(gh api "repos/$GITHUB_REPOSITORY/git/ref/tags/$TAG" --jq '.object.sha')"
capture PKG_REV "$pkg_rev"
# PKG_HASH is supplied by CI
