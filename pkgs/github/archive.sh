#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

version="$1"
os="$2"
arch="$3"
echo "./pkgs/github/archive.sh $version $os $arch"

rm -rf "tmp/$os-$arch"
repo="$(basename -s .git "$(git remote get-url origin)")"
bin="tmp/$os-$arch/$repo"
CGO_ENABLED=0 go build -ldflags "-s -w -buildid=github-$version" -trimpath -o "$bin"

tar -czf "$repo-$os-$arch.tar.gz" "$bin"
