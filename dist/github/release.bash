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
repo_name="$(basename "$(pwd)")"
# Disable CGO to ensure static linking
CGO_ENABLED=0 go build -ldflags "-s -w -buildid=github-$version" -trimpath -o "tmp/$os-$arch/$repo_name"

cp LICENSE "tmp/$os-$arch"
cp -r docs/* "tmp/$os-$arch"

cd "tmp/$os-$arch"
docs=()
while IFS= read -r -d '' file; do
  docs+=("$file")
done < <(git ls-files -z --others '*.md')

tar -czf "$repo_root/$repo_name-$os-$arch.tar.gz" LICENSE "${docs[@]}" "$repo_name"
