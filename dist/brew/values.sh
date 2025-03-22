#!/usr/bin/env bash

capture() {
    eval "$1=\"$2\""
    echo "$1 = $2"
}

repo_name="$(basename "$GITHUB_REPOSITORY")"
capture app_name "$repo_name"
capture class_name "$(awk 'BEGIN{print toupper(substr("'"$repo_name"'",1,1)) substr("'"$repo_name"'",2)}')"
capture description "$(gh repo view --json description --jq .description)"
capture homepage "$(gh api "repos/$GITHUB_REPOSITORY" --jq .homepage)"
url="$(gh api "repos/$GITHUB_REPOSITORY/releases/latest" --jq .tarball_url)"
capture url "$url"
capture sha256 "$(curl -sL "$url" | shasum -a 256 | cut -d ' ' -f1)"
capture repository "github.com/$GITHUB_REPOSITORY"
capture go_version "$(go list -m -f '{{.GoVersion}}' | awk -F. '{print $1"."$2}')"
capture version "$(basename "$url")"
