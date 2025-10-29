{
  description = "Go development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nur-anttiharju.url = "github:anttiharju/nur-packages";
    nur-anttiharju.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self, nixpkgs, nixpkgs-unstable, nur-anttiharju, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      devPackages = pkgs: pkgs-unstable: anttiharju: with pkgs; [ # 1.893GB
        go # 263MB
        action-validator # 4MB
        actionlint
        anttiharju.relcheck
        editorconfig-checker
        golangci-lint
        (python313.withPackages (
          ps: with ps; [
            mkdocs-material # 239MB
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
          anttiharju = nur-anttiharju.packages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = devPackages pkgs pkgs-unstable anttiharju;
            shellHook = '''';
          };
        }
      );

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          pkgs-unstable = import nixpkgs-unstable { inherit system; };
          anttiharju = nur-anttiharju.packages.${system};
        in
        {
          ci = pkgs.dockerTools.buildImage {
            name = "ci";
            tag = "latest";
            copyToRoot = pkgs.buildEnv {
              name = "image-root";
              paths = devPackages pkgs pkgs-unstable anttiharju;
              pathsToLink = [ "/bin" ];
            };
          };
        }
      );
    };
}
