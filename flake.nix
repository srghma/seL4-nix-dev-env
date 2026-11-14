{
  description = "seL4 + l4v + Isabelle (local) + Isabelle/VSCode + seL4-nix-utils dev environment";

  inputs = {
    nixpkgs.url = "path:/home/srghma/projects/nixpkgs";

    # Handled outside seL4-nix-utils
    isabelle-src = {
      url = "path:/home/srghma/seL4/isabelle";
      flake = false;
    };

    # Manifests
    sel4test-manifest-src = {
      url = "path:/home/srghma/seL4/sel4test-manifest";
      flake = false;
    };
    camkes-vm-examples-manifest-src = {
      url = "path:/home/srghma/seL4/camkes-vm-examples-manifest";
      flake = false;
    };

    # Core seL4 & capdl (top-level submodules)
    seL4-src = {
      url = "path:/home/srghma/seL4/seL4";
      flake = false;
    };
    capdl-src = {
      url = "path:/home/srghma/seL4/capdl";
      flake = false;
    };

    # Inner workspace submodules (camkes-vm-examples-ws & sel4test-ws)
    camkes-tool-src = {
      url = "path:/home/srghma/seL4/camkes-vm-examples-ws/projects/camkes-tool";
      flake = false;
    };
    camkes-vm-examples-src = {
      url = "path:/home/srghma/seL4/camkes-vm-examples-ws/projects/vm-examples";
      flake = false;
    };
    camkes-vm-images-src = {
      url = "path:/home/srghma/seL4/camkes-vm-examples-ws/projects/camkes-vm-images";
      flake = false;
    };
    camkes-vm-linux-src = {
      url = "path:/home/srghma/seL4/camkes-vm-examples-ws/projects/vm-linux";
      flake = false;
    };
    camkes-vm-src = {
      url = "path:/home/srghma/seL4/camkes-vm-examples-ws/projects/vm";
      flake = false;
    };
    global-components-src = {
      url = "path:/home/srghma/seL4/camkes-vm-examples-ws/projects/global-components";
      flake = false;
    };
    libzmq-src = {
      url = "path:/home/srghma/seL4/camkes-vm-examples-ws/projects/libzmq";
      flake = false;
    };
    lwip-src = {
      url = "path:/home/srghma/seL4/camkes-vm-examples-ws/projects/lwip";
      flake = false;
    };
    musllibc-src = {
      url = "path:/home/srghma/seL4/camkes-vm-examples-ws/projects/musllibc";
      flake = false;
    };
    nanopb-src = {
      url = "path:/home/srghma/seL4/sel4test-ws/tools/nanopb";
      flake = false;
    };
    opensbi-sel4test-src = {
      url = "path:/home/srghma/seL4/sel4test-ws/tools/opensbi";
      flake = false;
    };
    picotcp-src = {
      url = "path:/home/srghma/seL4/camkes-vm-examples-ws/projects/picotcp";
      flake = false;
    };
    polly-src = {
      url = "path:/home/srghma/seL4/camkes-vm-examples-ws/tools/polly";
      flake = false;
    };
    projects-libs-src = {
      url = "path:/home/srghma/seL4/camkes-vm-examples-ws/projects/projects_libs";
      flake = false;
    };
    seL4-libs-src = {
      url = "path:/home/srghma/seL4/camkes-vm-examples-ws/projects/seL4_libs";
      flake = false;
    };
    seL4-projects-libs-src = {
      url = "path:/home/srghma/seL4/camkes-vm-examples-ws/projects/seL4_projects_libs";
      flake = false;
    };
    seL4-tools-src = {
      url = "path:/home/srghma/seL4/camkes-vm-examples-ws/tools/seL4";
      flake = false;
    };
    sel4runtime-src = {
      url = "path:/home/srghma/seL4/camkes-vm-examples-ws/projects/sel4runtime";
      flake = false;
    };
    sel4test-src = {
      url = "path:/home/srghma/seL4/sel4test-ws/projects/sel4test";
      flake = false;
    };
    util-libs-src = {
      url = "path:/home/srghma/seL4/camkes-vm-examples-ws/projects/util_libs";
      flake = false;
    };

    seL4-nix-utils = {
      url = "path:/home/srghma/seL4/seL4-nix-utils";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        sel4test-manifest-src.follows = "sel4test-manifest-src";
        camkes-vm-examples-manifest-src.follows = "camkes-vm-examples-manifest-src";
        seL4-src.follows = "seL4-src";
        capdl-src.follows = "capdl-src";
        camkes-tool-src.follows = "camkes-tool-src";
        camkes-vm-examples-src.follows = "camkes-vm-examples-src";
        camkes-vm-images-src.follows = "camkes-vm-images-src";
        camkes-vm-linux-src.follows = "camkes-vm-linux-src";
        camkes-vm-src.follows = "camkes-vm-src";
        global-components-src.follows = "global-components-src";
        libzmq-src.follows = "libzmq-src";
        lwip-src.follows = "lwip-src";
        musllibc-src.follows = "musllibc-src";
        nanopb-src.follows = "nanopb-src";
        opensbi-sel4test-src.follows = "opensbi-sel4test-src";
        picotcp-src.follows = "picotcp-src";
        polly-src.follows = "polly-src";
        projects-libs-src.follows = "projects-libs-src";
        seL4-libs-src.follows = "seL4-libs-src";
        seL4-projects-libs-src.follows = "seL4-projects-libs-src";
        seL4-tools-src.follows = "seL4-tools-src";
        sel4runtime-src.follows = "sel4runtime-src";
        sel4test-src.follows = "sel4test-src";
        util-libs-src.follows = "util-libs-src";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      isabelle-src,
      seL4-nix-utils,
      ...
    }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          isabelle = pkgs.callPackage ./nix/isabelle.nix {
            isabelleSrc = isabelle-src;
          };
          isabelle-vscode = pkgs.callPackage ./nix/isabelle-vscode.nix {
            inherit isabelle;
            isabelleSrc = isabelle-src;
          };
        in
        seL4-nix-utils.packages.${system}
        // {
          inherit isabelle isabelle-vscode;
          verit = pkgs.verit;
          default = isabelle;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pkgsSeL4 = pkgs.extend seL4-nix-utils.overlays.default;
          isabelle = self.packages.${system}.isabelle;
          isabelle-vscode = self.packages.${system}.isabelle-vscode;
        in
        {
          default = pkgs.mkShell {
            packages =
              (with pkgs; [
                # Isabelle + VSCode extension
                isabelle
                # isabelle-vscode

                # Already in system PATH (/run/current-system/sw/bin):
                # antigravity-ide
                # just
                # git
                # curl
                # rsync
                # zstd

                # l4v proof dependencies
                mlton
                stack
                cabal-install
                haskell.compiler.ghc94
                (texliveMedium.withPackages (
                  ps: with ps; [
                    collection-latexextra
                    collection-bibtexextra
                    collection-metapost
                  ]
                ))
                librsvg

                # seL4 / CAmkES build & simulation tools
                ccache
                cmake
                cmakeCurses
                dtc
                gitRepo
                libxml2
                ncurses
                ninja
                protobuf
                qemu_full
                ubootTools

                # Cross compilers for ARM, AArch64, RISC-V
                pkgsCross.arm-embedded.buildPackages.gcc
                pkgsCross.aarch64-multiplatform.buildPackages.gcc
                pkgsCross.riscv64-embedded.buildPackages.gcc
              ])
              ++ (import "${seL4-nix-utils}/pkgs/camkes-deps.nix" {
                inherit (pkgsSeL4) cmake-format python3Packages;
              });

            env = {
              ISABELLE_VSCODE_VSIX = "${isabelle-vscode}/isabelle-2.0.0.vsix";
            };

            shellHook = ''
              echo "Isabelle: $(isabelle version) | VSIX: $ISABELLE_VSCODE_VSIX"
              echo "Run 'just --list' for available tasks."
            '';
          };
        }
      );
    };
}
