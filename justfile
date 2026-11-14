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

# Build test-isabelle (Untyped_Lambda), print warnings, and copy output to copyq
test-isabelle-build-with-warnings:
    #!/usr/bin/env nu
    let b = (^nix develop -c isabelle build -d test-isabelle -o threads=2 -j 1 Untyped_Lambda | complete)
    let w = (^nix develop -c isabelle build_log -H "Warning" -U -m 100 Untyped_Lambda | complete)
    let out = ([($b.stdout | str trim) ($b.stderr | str trim) ($w.stdout | str trim) ($w.stderr | str trim)] | where { $in != "" } | str join "\n")
    print $out
    $out | ^copyq add -
    ^copyq select 0
    if $b.exit_code != 0 { exit $b.exit_code }

# List available l4v proof tests
l4v-list arch="ARM":
    cd l4v && nix develop ..#default -c env L4V_ARCH={{ arch }} ./run_tests -l

# Run l4v proof tests via ./run_tests (arch: ARM, ARM_HYP, X64, RISCV64, AARCH64)
l4v-test arch="ARM" *tests: build-isabelle
    #!/usr/bin/env bash
    set -euo pipefail
    ROOT_DIR="$PWD"
    ISA_DIR="$(readlink -f result-isabelle)/share/Isabelle2026-git"
    trap 'ln -sfn ../isabelle "$ROOT_DIR/l4v/isabelle"' EXIT
    ln -sfn "$ISA_DIR" "$ROOT_DIR/l4v/isabelle"
    cd l4v && nix develop ..#default -c env L4V_ARCH={{ arch }} ISABELLE_THREADS=2 ./run_tests -v -j 1 --scale-timeouts 3 {{ tests }}

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
