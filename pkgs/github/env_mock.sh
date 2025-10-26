#!/usr/bin/env bash
set -euo pipefail

remote_url="$(git remote get-url origin 2>/dev/null || echo "")"

if [[ "$remote_url" =~ github.com[:/]([^/]+)/([^/.]+) ]]; then
  owner="${BASH_REMATCH[1]}"
  repo_name="${BASH_REMATCH[2]}"
  GITHUB_REPOSITORY="$owner/$repo_name"
fi
GITHUB_SHA="$(git rev-parse HEAD)"

export GITHUB_REPOSITORY
export GITHUB_SHA
