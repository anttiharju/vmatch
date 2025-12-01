#!/usr/bin/env bash
set -euo pipefail

#remote_url=https://example.com/owner/repository.git
#remote_url=git@example.com:owner/repository.git
remote_url="$(git remote get-url origin)"

normalized_url="${remote_url/://}"
temp="${normalized_url%/*}"
owner="$(basename "$temp")"

repo="$(basename --suffix .git "$remote_url")"
export GITHUB_REPOSITORY="$owner/$repo"

if [[ "$TAG" = "v0.0.0" ]]; then
  rev="$(gh api "repos/$GITHUB_REPOSITORY/commits/HEAD" --jq '.sha')"
else
  rev="$(gh api "repos/$GITHUB_REPOSITORY/git/ref/tags/$TAG" --jq '.object.sha')"
fi
export GITHUB_SHA="$rev"
