#!/usr/bin/env bash
set -euo pipefail
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

tag="$1"
target="$2"
echo "$0 $tag $target"

remote_url="$(git remote get-url origin)"
repo="$(basename --suffix .git "$remote_url")"
go build -ldflags "-s -w -buildid=github-$tag" -trimpath -o "target/$target/release/$repo"

cd "target/$target/release"
tar -czf "$repo_root/$repo-$target.tar.gz" "$repo"
