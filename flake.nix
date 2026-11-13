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
  };

  outputs =
    {
      self,
      nixpkgs,
      isabelle-src,
      seL4-nix-utils,
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
        {
          inherit isabelle isabelle-vscode;
          verit = pkgs.verit;
          default = isabelle;
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
              # Isabelle + VSCode extension + IDE
              isabelle
              isabelle-vscode
              just
              antigravity-ide

              # l4v proof dependencies
              mlton
              stack
              haskell.compiler.ghc94
              texliveMedium
              rsync
              librsvg
              zstd

              # seL4 / CAmkES build & simulation tools
              ccache
              cmake
              cmakeCurses
              curl
              dtc
              git
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
