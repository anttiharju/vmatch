#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${GITHUB_REPOSITORY:-}" ]]; then
  echo "GITHUB_REPOSITORY is not set" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
repo_name="$(basename "$GITHUB_REPOSITORY")"
tarball_url="https://api.github.com/repos/anttiharju/$repo_name/tarball/$TAG"

bottle_section() {
  bottle_lines="$(find "$REPO_ROOT" -maxdepth 1 -name 'vmatch-*.bottle.*.tar.gz' -exec "$REPO_ROOT/dist/brew/bottle.bash" {} \;)"
  echo "

  bottle do
    root_url 'https://github.com/anttiharju/$repo_name/releases/download/$TAG'
    rebuild 1
$bottle_lines
  end"
}

bottle_section=""
if [[ -z "${SKIP_BOTTLES:-}" ]]; then
  bottle_section="$(bottle_section)"
fi

capture() {
  eval "$1=\"$2\""
  echo "$1=\"$2\""
}

capture class_name "$(awk 'BEGIN{print toupper(substr("'"$repo_name"'",1,1)) substr("'"$repo_name"'",2)}')"
capture description "$(gh repo view --json description --jq .description)"
capture homepage "$(gh api "repos/$GITHUB_REPOSITORY" --jq .homepage)"
capture url "$tarball_url"
capture sha256 "$(curl -sL "$tarball_url" | shasum -a 256 | cut -d ' ' -f1)"
capture repository "github.com/$GITHUB_REPOSITORY"
capture go_version "$(grep -E '^go [0-9.]+' "$REPO_ROOT/go.mod" | cut -c4- | awk -F. '{print $1"."$2}')"
capture bottle "$bottle_section"
capture version "$TAG"
capture app_name "$repo_name"
