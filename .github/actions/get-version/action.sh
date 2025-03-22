#!/usr/bin/env bash
set -euo pipefail

source ../../../dist/brew/values.sh

echo "version=$version" >> "$GITHUB_OUTPUT"
