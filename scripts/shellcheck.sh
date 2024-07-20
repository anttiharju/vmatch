#!/bin/bash
set -euo pipefail

find . -iname "*.sh" -exec shellcheck {} +
