{
  description = "Go development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs, nixpkgs-unstable, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      devPackages = pkgs: pkgs-unstable: with pkgs; [
        go
        action-validator
        actionlint
        # relcheck
        editorconfig-checker
        golangci-lint
        (python313.withPackages (
          ps: with ps; [
            mkdocs-material
          ]
        ))
        pkgs-unstable.prettier
        rubocop
        shellcheck
      ];
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          pkgs-unstable = import nixpkgs-unstable { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = devPackages pkgs pkgs-unstable;
            shellHook = '''';
          };
        }
      );

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          pkgs-unstable = import nixpkgs-unstable { inherit system; };
        in
        {
          ci = pkgs.dockerTools.buildImage {
            name = "ci";
            tag = "latest";
            copyToRoot = pkgs.buildEnv {
              name = "image-root";
              paths = devPackages pkgs pkgs-unstable;
              pathsToLink = [ "/bin" ];
            };
          };
        }
      );
    };
}
