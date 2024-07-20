#!/bin/bash
set -euco pipefail

find . -iname "*.sh" -exec shellcheck {} +
