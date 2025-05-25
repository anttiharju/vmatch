#!/usr/bin/env bash
set -eu
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

version="$1"
os="$2"
arch="$3"

rm -rf "tmp/$os-$arch"
go build -ldflags "-s -w -buildid=github-$version" -o "tmp/$os-$arch/release/bin/vmatch"

cp LICENSE "tmp/$os-$arch"
cp -r docs/* "tmp/$os-$arch"
cd "tmp/$os-$arch"

docs=()
while IFS= read -r -d '' file; do
  docs+=("$file")
done < <(git ls-files -z --others '*.md')

tar -czf "$repo_root/vmatch-$os-$arch.tar.gz" LICENSE release/bin "${docs[@]}"
