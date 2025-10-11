{
  description = "Go & golangci-lint version automation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.buildGoModule {
            name = "vmatch";
            src = ./.;
            vendorHash = null;

            installPhase = ''
              mkdir -p $out/bin
              install -Dm755 $GOPATH/bin/vmatch $out/bin/vmatch
            '';
          };
        }
      );
    };
}
