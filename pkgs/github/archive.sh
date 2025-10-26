#!/usr/bin/env bash
set -euo pipefail
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

version="$1"
os="$2"
arch="$3"
echo "./pkgs/github/archive.sh $version $os $arch"

rm -rf "tmp/$os-$arch"
remote_url="$(git remote get-url origin)"
repo="$(basename -s .git "$remote_url")"
bin="tmp/$os-$arch/$repo"
CGO_ENABLED=0 go build -ldflags "-s -w -buildid=github-$version" -trimpath -o "$bin"

tar -czf "$repo-$os-$arch.tar.gz" "$bin"
