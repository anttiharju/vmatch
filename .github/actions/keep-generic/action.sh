#!/usr/bin/env sh
set -eu
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root" || exit 1

repo_name="$(basename "$repo_root")"
forbidden=$(git grep -l "$repo_name" -- ':!internal/' ':!docs/' ':!go.mod' ':!main.go' ':!mkdocs.yml' || true)
if [ -n "$forbidden" ]; then
    echo "ERROR: Found references to '$repo_name' outside of internal/ or docs/ directories:"
    echo "$forbidden"
    exit 1
fi
