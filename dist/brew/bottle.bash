#!/usr/bin/env bash
set -euo pipefail

file="$1"
platform_arch=$(basename "$file" | grep -o '[^.]*\.[^.]*\.bottle' | sed 's/\.bottle$//' | sed 's/^vmatch-[0-9]*\.//')
hash=$(shasum -a 256 "$file" | cut -d ' ' -f1)

echo "    sha256 cellar: :any, $platform_arch: '$hash'"
