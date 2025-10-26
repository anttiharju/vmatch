#!/usr/bin/env bash
set -euo pipefail

#remote_url=https://example.com/owner/repository.git
#remote_url=git@example.com:owner/repository.git
remote_url="$(git remote get-url origin)"

normalized_url="${remote_url/://}"
temp="${normalized_url%/*}"
owner="$(basename "$temp")"

repository="$(basename -s .git "$remote_url")"

tag_sha="$(git rev-list -n 1 "$RENDER_TAG")"

export GITHUB_REPOSITORY="$owner/$repository"
export GITHUB_SHA="$tag_sha"
