#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

version="$1"
os="$2"
arch="$3"
echo "./dist/github/release.bash $version $os $arch"

rm -rf "tmp/$os-$arch"
repo_name="$(basename "$(pwd)")"
CGO_ENABLED=0 go build -ldflags "-s -w -buildid=github-$version" -trimpath -o "tmp/$os-$arch/$repo_name"

cd "tmp/$os-$arch"
tar -czf "$repo_root/$repo_name-$os-$arch.tar.gz" "$repo_name"
