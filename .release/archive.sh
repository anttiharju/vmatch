#!/usr/bin/env bash
set -euo pipefail
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

tag="$1"
os="$2"
arch="$3"
target="$os-$arch"
echo "$0 $tag $os $arch"

rm -rf "tmp/$target"
remote_url="$(git remote get-url origin)"
repo="$(basename --suffix .git "$remote_url")"
go build -ldflags "-s -w -buildid=github-$tag" -trimpath -o "tmp/$target/$repo"

cd "tmp/$target"
tar -czf "$repo_root/$repo-$target.tar.gz" "$repo"
