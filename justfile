default:
    @just --list

# Build Isabelle (from ./isabelle) and the VSCode extension
build: build-isabelle build-vscode

# Build Isabelle from ./isabelle
build-isabelle:
    nix build .#isabelle --max-jobs 2 --cores 3 -o result-isabelle

# Build Isabelle/VSCode extension (.vsix)
build-vscode:
    nix build .#isabelle-vscode --max-jobs 2 --cores 3 -o result-vscode

# Install the Nix-built Isabelle VSCode extension into antigravity-ide
install-vscode-ext: build-vscode
    antigravity-ide --install-extension ./result-vscode/isabelle-2.0.0.vsix --force
    antigravity-ide --list-extensions | rg -i isabelle

# Launch antigravity-ide inside the flake environment
ide dir=".":
    nix develop -c antigravity-ide {{ dir }}

# Launch Isabelle/jEdit inside the flake environment
jedit *args:
    nix develop -c isabelle jedit {{ args }}

# Start Isabelle VSCode language server
vscode-server *args:
    nix develop -c isabelle vscode_server {{ args }}

# Run l4v proof tests (arch: ARM, ARM_HYP, X64, RISCV64, AARCH64)
l4v-test arch="ARM" *args:
    cd l4v && nix develop ..#default -c ./run_tests -v {{ arch }} {{ args }}

# Configure and build seL4 test suite in build-<plat>
sel4-build plat="x86_64" sim="TRUE":
    mkdir -p build-{{ plat }}
    cd build-{{ plat }} && nix develop ..#default -c cmake -DCROSS_COMPILER_PREFIX= -DPLATFORM={{ plat }} -DSIMULATION={{ sim }} -G Ninja ../seL4
    cd build-{{ plat }} && nix develop ..#default -c ninja

# Check flake evaluation
check:
    nix flake check --no-build

# Update local ./isabelle git repo and refresh flake lock input
update-isabelle:
    git -C isabelle pull --ff-only
    nix flake update isabelle-src
