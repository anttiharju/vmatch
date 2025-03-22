description=$(gh repo view  --json description --jq .description)
url=$(gh api "repos/$GITHUB_REPOSITORY/releases/latest" --jq .tarball_url)
homepage=$(gh api "repos/$GITHUB_REPOSITORY" --jq .homepage)
go_version=$(go list -m -f '{{.GoVersion}}')
version=$(basename "$url")
github_event_repository_name="$GITHUB_EVENT_REPOSITORY_NAME"
