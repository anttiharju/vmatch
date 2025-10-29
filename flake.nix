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
      container_version = "0.1.0";
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      devPackages = pkgs: pkgs-unstable: anttiharju: system: with pkgs; [
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
        gh
        # Everything below is required by GitHub Actions
        coreutils
        bash
        git
        findutils
        gnutar
        curl
        jq
        gzip
      ] ++ pkgs.lib.optionals (system == "aarch64-linux" || system == "x86_64-linux") [
        cacert
      ];
    in
    {
      container_version = container_version;
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          pkgs-unstable = import nixpkgs-unstable { inherit system; };
          anttiharju = nur-anttiharju.packages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = devPackages pkgs pkgs-unstable anttiharju system;
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

          # nix-ld is required because GitHub Actions mounts dynamically linked node binaries into the container
          libDir = if builtins.elem system [ "x86_64-linux" "aarch64-linux" ]
            then "/lib64"
            else "/lib";

          nix-ld-setup = pkgs.runCommand "nix-ld-setup" {} ''
            mkdir -p $out${libDir}
            install -D -m755 ${pkgs.nix-ld}/libexec/nix-ld $out${libDir}/$(basename ${pkgs.stdenv.cc.bintools.dynamicLinker})
          '';
        in
        pkgs.lib.optionalAttrs (system == "x86_64-linux" || system == "aarch64-linux") {
          ci = pkgs.dockerTools.buildImage {
            name = "ci";
            tag = container_version;
            copyToRoot = pkgs.buildEnv {
              name = "image-root";
              paths = (devPackages pkgs pkgs-unstable anttiharju system) ++ [ nix-ld-setup ];
              pathsToLink = [ "/bin" "/lib" "/lib64" "/usr" ];
            };
            config = {
              Env = [
                "NIX_LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [
                  pkgs.stdenv.cc.cc.lib
                  pkgs.glibc
                ]}"
                "NIX_LD=${pkgs.stdenv.cc.bintools.dynamicLinker}"
              ];
              User = "1001"; # https://github.com/actions/runner/issues/2033#issuecomment-1598547465
            };
            runAsRoot = ''
              #!${pkgs.runtimeShell}

              # /usr/bin/env for shebangs
              mkdir -p /usr/bin
              ln -sf ${pkgs.coreutils}/bin/env /usr/bin/env

              # Symlink all binaries to /usr/bin for GitHub Actions compatibility (e.g. setup-go modifies PATH and we lose /bin)
              for binary in /bin/*; do
                if [ -f "$binary" ] || [ -L "$binary" ]; then
                  realpath=$(readlink -f "$binary")
                  ln -sf "$realpath" /usr/bin/$(basename "$binary")
                fi
              done

              # /usr/local/bin
              mkdir -p /usr/local/bin
              chmod 755 /usr/local/bin

              # cacert
              mkdir -p /etc/ssl/certs
              ln -sf ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt
              ln -sf ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-bundle.crt

              # To fix 'parallel golangci-lint is running'
              mkdir -p /tmp
              chmod 1777 /tmp
            '';
          };
        }
      );
    };
}
