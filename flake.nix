# Standard Rust dev shell with a few extras for SQLx
# - https://nixos.wiki/wiki/Rust
#
# nativeBuildInputs vs buildInputs vs packages
# - for mkShells they are all treated the same
# - [longer explanation](https://discourse.nixos.org/t/use-buildinputs-or-nativebuildinputs-for-nix-shell/8464)
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/3566ab7246670a43abd2ffa913cc62dad9cdf7d5";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs { inherit system; };
  in
  {
    devShells.default = pkgs.mkShell {
      nativeBuildInputs = with pkgs; [
        pkg-config
        clang
        llvmPackages.bintools
        gcc
        rustc
        rustup
        cargo
        rustfmt
        clippy
        glibc
        sqlite
        sqlx-cli
      ];

      # Set the rust source path for rust-analyzer to be happy
      RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

      # Launch VSCode in the dev shell
      shellHook = ''
        echo "Launching rust API componet in vscode... `code api`"
      '';
    };
  });
}
