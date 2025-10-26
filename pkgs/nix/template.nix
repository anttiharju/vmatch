{ buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "${REPO_NAME}";
  version = "${VERSION}";

  src = fetchFromGitHub {
    owner = "${REPO_OWNER}";
    repo = "${REPO_NAME}";
    rev = "${GITHUB_SHA}";
    hash = "${HASH}";
  };

  vendorHash = null;
}
