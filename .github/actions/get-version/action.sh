#!/usr/bin/env bash
set -euo pipefail

source ../../../dist/brew/values.sh

if [[ -z "${version-}" ]]; then
    echo "Error: version variable not set by values.sh" >&2
    exit 1
fi

echo "version=$version" >> "$GITHUB_OUTPUT"
