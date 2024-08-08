#!/bin/sh
set -eu

find . -type f \( -iname "*.sh" -o -path "./.githooks/*" \) -exec shellcheck {} +
