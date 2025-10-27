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
    "-X main.version=v${PKG_VERSION}"
    "-X main.time=${PKG_TIME}"
    "-X main.rev=${PKG_REV}"
  ];

  vendorHash = null;
}
# antti@harju ~> which vmatch
# /opt/homebrew/bin/vmatch
# antti@harju ~> vmatch version
# vmatch has version 1.0.29 built with go1.24.6 from d4e108f4 on 2025-10-27T14:04:44Z
# antti@harju ~> /etc/profiles/per-user/antti/bin/vmatch version
# vmatch has version (devel) built with go1.24.6 from  on

# details needed:
# version: 1.0.29
# commit (short): there's already enough info via PKG_REV
# date: can hardcode to 1970-01-01T00:00:00Z

# prior art:
# https://github.com/NixOS/nixpkgs/blob/ff5260b7d0a40d726bbbc9e8e82ccfb9a79e92eb/pkgs/by-name/go/golangci-lint/package.nix#L35-L37
# https://github.com/NixOS/nixpkgs/blob/5afd88b9868f7220f9e4022f4cf363d858309d07/pkgs/by-name/ac/actionlint/package.nix#L48
