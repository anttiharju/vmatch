#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

source dist/brew/values.bash
echo "version=$version"
