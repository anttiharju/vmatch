{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "${PKG_REPO}";
  version = "${PKG_VERSION}";
  revision = "${PKG_REV}";

  src = fetchFromGitHub {
    owner = "${PKG_OWNER}";
    repo = "${PKG_REPO}";
    rev = revision;
    hash = "${PKG_HASH}";
  };

  vendorHash = null;

  ldflags = [
    "-s"
    "-w"
    "-X main.revision=$${revision}"
    "-X main.version=$${version}"
    "-X main.time=${PKG_TIME}"
  ];

  meta = {
    homepage = "${PKG_HOMEPAGE}";
    description = "${PKG_DESC}";
    changelog = "https://github.com/${PKG_OWNER}/${PKG_REPO}/releases/tag/v$${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ${PKG_OWNER} ];
    mainProgram = "${PKG_REPO}";
  };
}
