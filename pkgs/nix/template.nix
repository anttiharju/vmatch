{ buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "${repo_name}";
  version = "${version}";

  src = fetchFromGitHub {
    owner = "${repo_owner}";
    repo = "${repo_name}";
    rev = "${GITHUB_SHA}";
    hash = "${hash}";
  };

  vendorHash = null;
}
