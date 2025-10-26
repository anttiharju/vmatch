#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
repo_name="$(basename "$repo_root")"
remote_url="$(git remote get-url origin 2>/dev/null || echo "")"

if [[ "$remote_url" =~ github.com[:/]([^/]+)/([^/.]+) ]]; then
  owner="${BASH_REMATCH[1]}"
  GITHUB_REPOSITORY="$owner/$repo_name"
fi
GITHUB_SHA="$(git rev-parse HEAD)"

export GITHUB_REPOSITORY
export GITHUB_SHA
