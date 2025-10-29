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

      devPackages = pkgs: pkgs-unstable: anttiharju: with pkgs; [
        go # 263MB
        action-validator # 4MB
        actionlint # 121MB
        anttiharju.relcheck # 2MB
        editorconfig-checker # 4MB
        golangci-lint # 41MB
        (python313.withPackages (
          ps: with ps; [
            mkdocs-material # 239MB
          ]
        ))
        pkgs-unstable.prettier # 217MB
        rubocop # 805MB
        shellcheck # 123MB (note: also included by actionlint)
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
