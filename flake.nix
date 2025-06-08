# Standard Rust dev shell with a few extras for SQLx
# - https://nixos.wiki/wiki/Rust
#
# nativeBuildInputs vs buildInputs vs packages
# - for mkShells they are all treated the same
# - [longer explanation](https://discourse.nixos.org/t/use-buildinputs-or-nativebuildinputs-for-nix-shell/8464)
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/2795c506fe8fb7b03c36ccb51f75b6df0ab2553f";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs { inherit system; };
  in
  {
    devShells.default = pkgs.mkShell {

      # Supporting tooling
      packages = with pkgs; [
        mysql-workbench # Useful for designing relational table EER Diagrams
        sqlitebrowser   # Useful for examining the database
      ];

      # Build packages
      # * By calling out both rustc and glibc here I was able to work around a GLIBC versioning 
      #   issue I was seeing related to using rustup to install my rustc system version.
      nativeBuildInputs = with pkgs; [
        bashInteractive # Solve for normal shell operation
        pkg-config      # System dependency path resolution
        rustc           # Ensure we have Rust available
        cargo           # Rust build tooling
        glibc           # System dependency for SQLx macros
        sqlx-cli        # SQLx command line tool
      ];

      # Set the rust source path for rust-analyzer to be happy
      RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

      # Launch VSCode in the dev shell
      shellHook = ''
        echo "Launch vscode for flutter with 'code .' or for the api with 'code api'"
      '';
    };
  });
}
