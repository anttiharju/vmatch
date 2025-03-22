#!/usr/bin/env bash
set -euo pipefail

# Normalise working directory
cd "$(dirname "${BASH_SOURCE[0]}")"

source ../../../dist/brew/values.sh

echo "version=$version" >> "$GITHUB_OUTPUT"
