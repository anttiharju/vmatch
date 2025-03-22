#!/usr/bin/env bash

export GITHUB_REPOSITORY=anttiharju/vmatch

set -a
source values.sh
set +a
envsubst < template.rb > formula.rb
