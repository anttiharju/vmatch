{
  description = "Go development environment";

  nixConfig.extra-substituters = [
    "https://nix-community.cachix.org"
    "https://anttiharju.cachix.org"
  ];
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
    nur-anttiharju.url = "github:anttiharju/nur-packages";
    nur-anttiharju.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nur-anttiharju,
      ...
    }:
    let
      container_version = "1.0.0";
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      devPackages =
        pkgs: anttiharju: system: with pkgs; [
          go
          action-validator
          actionlint
          anttiharju.relcheck
          editorconfig-checker
          (python313.withPackages (
            ps: with ps; [
              mkdocs-material
            ]
          ))
          prettier
          rubocop
          shellcheck
          gh
          yq-go
          ripgrep
          # Everything below is required by GitHub Actions
          uutils-coreutils-noprefix
          bash
          git
          findutils
          gnutar
          curl
          jq
          gzip
          envsubst
          gawkInteractive
          xz
          gnugrep
        ];
    in
    {
      container_version = container_version; # This is here so that 'nix eval .#container_version --raw' works
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          anttiharju = nur-anttiharju.packages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = devPackages pkgs anttiharju system;

            shellHook = "lefthook install";
          };
        }
      );

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          anttiharju = nur-anttiharju.packages.${system};

          # Fix not being able to run the unpatched node binaries that GitHub Actions mounts into the container
          nix_ld_setup = pkgs.runCommand "nix-ld-setup" { } ''
            mkdir -p $out/lib64
            install -D -m755 ${pkgs.nix-ld}/libexec/nix-ld "$out/lib64/$(basename ${pkgs.stdenv.cc.bintools.dynamicLinker})"
          '';
        in
        pkgs.lib.optionalAttrs (system == "x86_64-linux" || system == "aarch64-linux") {
          ci = pkgs.dockerTools.streamLayeredImage {
            name = "ci";
            tag = container_version;
            contents = (devPackages pkgs anttiharju system) ++ [
              nix_ld_setup
              pkgs.dockerTools.caCertificates
              pkgs.sudo
              pkgs.nix.out
              pkgs.dockerTools.usrBinEnv
              anttiharju.compare-changes
            ];
            config = {
              User = "1001"; # https://github.com/actions/runner/issues/2033#issuecomment-1598547465
              Env = [
                "NIX_LD_LIBRARY_PATH=${
                  pkgs.lib.makeLibraryPath [
                    pkgs.stdenv.cc.cc.lib
                    pkgs.glibc
                  ]
                }"
                "NIX_LD=${pkgs.stdenv.cc.bintools.dynamicLinker}"
                # PATH has to be defined so that actions that manipulate it (e.g. setup-go) don't break the environment
                "PATH=/home/runner/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
              ];
            };
            enableFakechroot = true;
            fakeRootCommands = ''
              #!${pkgs.runtimeShell}

              # https://docs.github.com/en/actions/reference/runners/github-hosted-runners#administrative-privileges
              ${pkgs.dockerTools.shadowSetup}
              useradd -u 1001 -m runner
              echo "runner ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner
              chmod 0440 /etc/sudoers.d/runner
              mkdir -p /etc/pam.d
              {
                echo "auth       sufficient   pam_permit.so"
                echo "account    sufficient   pam_permit.so"
                echo "session    sufficient   pam_permit.so"
              } > /etc/pam.d/sudo
              chmod u+s /sbin/sudo

              # Fix 'parallel golangci-lint is running'
              mkdir -p /tmp
              chmod 1777 /tmp

              # Enable 'nix eval .#container_version --raw' and 'nix flake update' inside the container
              mkdir -p /etc/nix
              echo "experimental-features = nix-command flakes" > /etc/nix/nix.conf

              # Fix 'mv: No such file or directory (os error 2)'
              mkdir -p /usr/local/bin
              chmod 0777 /usr/local/bin
            '';
          };
        }
      );
    };
}
