#!/usr/bin/env bash
set -euo pipefail

capture() {
    eval "$1=\"$2\""
    echo "$1=\"$2\""
}

repo_name="$(basename "$GITHUB_REPOSITORY")"
tarball_url="$(gh api "repos/$GITHUB_REPOSITORY/releases/latest" --jq .tarball_url)"

capture class_name "$(awk 'BEGIN{print toupper(substr("'"$repo_name"'",1,1)) substr("'"$repo_name"'",2)}')"
capture description "$(gh repo view --json description --jq .description)"
capture homepage "$(gh api "repos/$GITHUB_REPOSITORY" --jq .homepage)"
capture url "$tarball_url"
capture sha256 "$(curl -sL "$tarball_url" | shasum -a 256 | cut -d ' ' -f1)"
capture repository "github.com/$GITHUB_REPOSITORY"
capture go_version "$(go list -m -f '{{.GoVersion}}' | awk -F. '{print $1"."$2}')"
capture app_name "$repo_name"

# Done manually to get robust static analysis from ShellCheck for get-version
version="$(basename "$tarball_url")"
echo "version=\"$version\""
