#!/usr/bin/env bash

source ../../../dist/brew/values.sh

# shellcheck disable=SC2154
echo "version=$version" >> "$GITHUB_OUTPUT"
