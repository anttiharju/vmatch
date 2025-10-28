#!/usr/bin/env bash
set -euo pipefail

capture() {
  eval "export $1=\"$2\""
  echo "export $1=\"$2\""
}

capture PKG_REPO "${GITHUB_REPOSITORY##*/}"
capture PKG_VERSION "${TAG#v}"
capture PKG_OWNER "${GITHUB_REPOSITORY%%/*}"
capture PKG_REV "$GITHUB_SHA"
sha256="$(nix-prefetch-url --quiet --unpack "https://github.com/$GITHUB_REPOSITORY/archive/$GITHUB_SHA.tar.gz")"
hash="$(nix hash convert --hash-algo sha256 --to sri "$sha256")"
capture PKG_HASH "$hash"
time=$(TZ=UTC git show --quiet --date=format-local:%Y-%m-%dT%H:%M:%SZ --format=%cd)
capture PKG_TIME "$time"
