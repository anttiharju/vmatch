#!/usr/bin/env bash
set -euo pipefail

file="$1"
platform_arch=$(basename "$file" | sed -E 's/^vmatch-[0-9]+\.[0-9]+\.[0-9]+\.//' | sed -E 's/\.bottle.*$//')
hash=$(shasum -a 256 "$file" | cut -d ' ' -f1)

echo "    sha256 cellar: :any, $platform_arch: '$hash'"
