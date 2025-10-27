{ buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "${PKG_REPO}";
  version = "${PKG_VERSION}";

  src = fetchFromGitHub {
    owner = "${PKG_OWNER}";
    repo = "${PKG_REPO}";
    rev = "${PKG_REV}";
    hash = "${PKG_HASH}";
  };

  ldflags = [
    "-s"
    "-w"
  ];

  vendorHash = null;
}
