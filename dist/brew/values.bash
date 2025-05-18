#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${GITHUB_REPOSITORY:-}" ]]; then
    echo "GITHUB_REPOSITORY is not set" >&2
    exit 1
fi

capture() {
    eval "$1=\"$2\""
    echo "$1=\"$2\""
}

repo_name="$(basename "$GITHUB_REPOSITORY")"
tarball_url="https://api.github.com/repos/anttiharju/vmatch/tarball/$TAG"

capture class_name "$(awk 'BEGIN{print toupper(substr("'"$repo_name"'",1,1)) substr("'"$repo_name"'",2)}')"
capture description "$(gh repo view --json description --jq .description)"
capture homepage "$(gh api "repos/$GITHUB_REPOSITORY" --jq .homepage)"
capture url "$tarball_url"
capture sha256 "$(curl -sL "$tarball_url" | shasum -a 256 | cut -d ' ' -f1)"
capture repository "github.com/$GITHUB_REPOSITORY"
capture go_version "$(grep -E '^go [0-9.]+' "$(git rev-parse --show-toplevel)/go.mod" | cut -c4- | awk -F. '{print $1"."$2}')"
capture version "$TAG"
capture app_name "$repo_name"

if [[ -n "${SKIP_BOTTLES:-}" ]]; then
    capture bottle ""
else
    capture bottle "
  bottle do
    root_url 'https://github.com/anttiharju/vmatch/releases/download/build102'
    rebuild 1
    sha256 cellar: :any, arm64_sonoma: 'a9a8bf4915c020acf579f96f59d0ebf1fc27742e8979ada188d4352d9969f44a'
    sha256 cellar: :any, arm64_sequoia: '81c4aa1255440c92f5233dbcbc9d9b8b60585090128754b13b2ebc91229dd5e7'
    sha256 cellar: :any, x86_64_linux: '75a681ef45406a10fe475c3eb8eb85548a5732b69d8260e6d6a3aa650607a5f7'
  end
"
fi
