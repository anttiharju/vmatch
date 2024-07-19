#!/usr/bin/env bash

find . -iname "*.sh" -exec shellcheck {} +
