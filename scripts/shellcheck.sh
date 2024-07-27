#!/bin/sh
set -eu

find . -path ./node_modules -prune -o -type f \( -iname "*.sh" -o -path "./.githooks/*" \) -exec shellcheck {} +
