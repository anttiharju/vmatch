#!/usr/bin/env bash
set -euo pipefail
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

version="$1"
os="$2"
arch="$3"
target="$os-$arch"
echo "$0 $version $target"

remote_url="$(git remote get-url origin)"
repo="$(basename --suffix .git "$remote_url")"
GOOS="$os" GOARCH="$arch" go build -ldflags "-s -w -buildid=github-$version" -trimpath -o "target/$target/release/$repo"

cd "target/$target/release"
tar -czf "$repo_root/$repo-$target.tar.gz" "$repo"
