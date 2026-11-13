{
  description = "seL4 + l4v + Isabelle (local git) + Isabelle/VSCode environment";

  inputs = {
    nixpkgs.url = "path:/home/srghma/projects/nixpkgs";
    isabelle-src = {
      url = "git+file:///home/srghma/seL4/isabelle";
      flake = false;
    };
    seL4-nix-utils = {
      url = "git+file:///home/srghma/seL4/seL4-nix-utils";
      flake = false;
    };
    seL4-src = {
      url = "git+file:///home/srghma/seL4/seL4";
      flake = false;
    };
    capdl-src = {
      url = "git+file:///home/srghma/seL4/capdl";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      isabelle-src,
      seL4-nix-utils,
      seL4-src,
      capdl-src,
    }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ (import "${seL4-nix-utils}/overlay.nix") ];
          };

          localCapDLTool = pkgs.capDL-tool.override {
            src = capdl-src;
          };

          capDLInjectorOverlay = _final: _prev: {
            capDL-tool = localCapDLTool;
          };

          pkgsCross =
            nixpkgs.lib.attrsets.genAttrs
              [
                "aarch64-unknown-none-elf"
                "armv7l-unknown-none-eabihf"
                "i686-unknown-none-elf"
                "riscv64-unknown-none-elf"
                "x86_64-unknown-none-elf"
              ]
              (
                config:
                import nixpkgs {
                  inherit system;
                  crossSystem = { inherit config; };
                  overlays = [
                    (import "${seL4-nix-utils}/overlay.nix")
                    capDLInjectorOverlay
                  ];
                }
              );

          isabelle = pkgs.callPackage ./nix/isabelle.nix {
            isabelleSrc = isabelle-src;
          };
          isabelle-vscode = pkgs.callPackage ./nix/isabelle-vscode.nix {
            inherit isabelle;
            isabelleSrc = isabelle-src;
          };
        in
        {
          inherit isabelle isabelle-vscode;
          verit = pkgs.verit;
          default = isabelle;

          capDL-tool = localCapDLTool;

          # Verified seL4 kernels using local ./seL4
          seL4-kernel-aarch64 = pkgsCross.aarch64-unknown-none-elf.buildSeL4Kernel {
            src = seL4-src;
            verifiedConfig = "AARCH64_verified";
          };
          seL4-kernel-arm = pkgsCross.armv7l-unknown-none-eabihf.buildSeL4Kernel {
            src = seL4-src;
            verifiedConfig = "ARM_verified";
          };
          seL4-kernel-arm-hyp = pkgsCross.armv7l-unknown-none-eabihf.buildSeL4Kernel {
            src = seL4-src;
            verifiedConfig = "ARM_HYP_verified";
          };
          seL4-kernel-riscv64 = pkgsCross.riscv64-unknown-none-elf.buildSeL4Kernel {
            src = seL4-src;
            verifiedConfig = "RISCV64_verified";
          };
          seL4-kernel-x64 = pkgsCross.x86_64-unknown-none-elf.buildSeL4Kernel {
            src = seL4-src;
            verifiedConfig = "X64_verified";
          };

          # seL4test QEMU targets using local ./seL4
          seL4-test-x86_64-simulate =
            pkgsCross.x86_64-unknown-none-elf.callPackage "${seL4-nix-utils}/pkgs/seL4-test.nix"
              {
                seL4Src = seL4-src;
                extraCmakeFlags = [
                  "-DPLATFORM=x86_64"
                  "-DSIMULATION=TRUE"
                ];
              };
          seL4-test-ia32-simulate =
            pkgsCross.i686-unknown-none-elf.callPackage "${seL4-nix-utils}/pkgs/seL4-test.nix"
              {
                seL4Src = seL4-src;
                extraCmakeFlags = [
                  "-DPLATFORM=ia32"
                  "-DSIMULATION=TRUE"
                ];
              };
          seL4-test-armv7l-zynq7000-simulate =
            pkgsCross.armv7l-unknown-none-eabihf.callPackage "${seL4-nix-utils}/pkgs/seL4-test.nix"
              {
                seL4Src = seL4-src;
                extraCmakeFlags = [
                  "-DPLATFORM=zynq7000"
                  "-DSIMULATION=1"
                ];
              };

          # CAmkES VM example for QEMU arm-virt using local ./seL4 & ./capdl
          seL4-camkes-vm-examples-aarch64-qemu-arm-virt =
            pkgsCross.aarch64-unknown-none-elf.callPackage "${seL4-nix-utils}/pkgs/seL4-camkes-vm-examples.nix"
              {
                seL4Src = seL4-src;
                capdlSrc = capdl-src;
                extraCmakeFlags = [
                  "-DPLATFORM=qemu-arm-virt"
                  "-DCAMKES_VM_APP=vm_minimal"
                ];
              };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pkgsSeL4 = pkgs.extend (import "${seL4-nix-utils}/overlay.nix");
          isabelle = self.packages.${system}.isabelle;
          isabelle-vscode = self.packages.${system}.isabelle-vscode;
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
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

              # Python deps from seL4-nix-utils (includes seL4-deps)
              pkgsSeL4.python3Packages.camkes-deps

              # Cross compilers for ARM, AArch64, RISC-V
              pkgsCross.arm-embedded.buildPackages.gcc
              pkgsCross.aarch64-multiplatform.buildPackages.gcc
              pkgsCross.riscv64-embedded.buildPackages.gcc
            ];

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
