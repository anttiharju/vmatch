{
  description = "Go development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      devPackages = pkgs: with pkgs; [
        go
      ];
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = devPackages pkgs;
            shellHook = '''';
          };
        }
      );

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          ci = pkgs.dockerTools.buildImage {
            name = "ci";
            tag = "latest";
            copyToRoot = pkgs.buildEnv {
              name = "image-root";
              paths = devPackages pkgs;
              pathsToLink = [ "/bin" ];
            };
          };
        }
      );
    };
}
