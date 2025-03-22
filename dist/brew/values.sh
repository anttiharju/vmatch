#!/usr/bin/env bash

app_name=$(basename "$GITHUB_REPOSITORY")
class_name=$(awk 'BEGIN{print toupper(substr("'"$app_name"'",1,1)) substr("'"$app_name"'",2)}')
description=$(gh repo view  --json description --jq .description)
homepage=$(gh api "repos/$GITHUB_REPOSITORY" --jq .homepage)

url=$(gh api "repos/$GITHUB_REPOSITORY/releases/latest" --jq .tarball_url)
sha256=$(curl -sL "$url" | shasum -a 256 | cut -d ' ' -f1)
repository="github.com/$GITHUB_REPOSITORY"

go_version=$(go list -m -f '{{.GoVersion}}' | awk -F. '{print $1"."$2}')
version=$(basename "$url")

echo "$app_name"
echo "$class_name"
echo "$description"
echo "$homepage"

echo "$url"
echo "$sha256"
echo "$repository"

echo "$go_version"
echo "$version"
