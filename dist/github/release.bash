#!/usr/bin/env bash
set -eu
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

version="$1"
os="$2"
arch="$3"

echo "$version"
echo "$os"
echo "$arch"

rm -rf "tmp/$os-$arch"
go build -ldflags "-s -w -buildid=github-$version" -trimpath -o "tmp/$os-$arch/vmatch"

cp LICENSE "tmp/$os-$arch"
cp docs/README.md "tmp/$os-$arch"

cd "tmp/$os-$arch"
tar -czf "$repo_root/vmatch-$os-$arch.tar.gz" LICENSE README.md vmatch
