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
    "-X main.revision=${PKG_REV}"
    "-X main.version=${PKG_VERSION}"
    "-X main.time=${PKG_TIME}"
  ];

  vendorHash = null;
}
