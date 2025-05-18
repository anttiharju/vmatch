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
capture TARBALL_URL "https://api.github.com/repos/anttiharju/vmatch/tarball/$TAG"
capture sha256 "$(curl -sL "$TARBALL_URL" | shasum -a 256 | cut -d ' ' -f1)"
capture repository "github.com/$GITHUB_REPOSITORY"
capture go_version "$(go list -m -f '{{.GoVersion}}' | awk -F. '{print $1"."$2}')"
capture version "$TAG"
capture app_name "$repo_name"
