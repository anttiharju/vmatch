#!/usr/bin/env dash
set -eu

find . -type f \( -iname "*.sh" -o -path "./.githooks/*" \) -exec shellcheck {} +
