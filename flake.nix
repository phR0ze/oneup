# Standard Rust dev shell with a few extras for SQLx
# - https://nixos.wiki/wiki/Rust
#
# nativeBuildInputs vs buildInputs vs packages
# - for mkShells they are all treated the same
# - [longer explanation](https://discourse.nixos.org/t/use-buildinputs-or-nativebuildinputs-for-nix-shell/8464)
{
  inputs = {
    # Update as of Jun 12, 2025 commit
    nixpkgs.url = "github:nixos/nixpkgs/3e3afe5174c561dee0df6f2c2b2236990146329f";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in
  {
    devShells.default = pkgs.mkShell {

      # Supporting tooling
      packages = with pkgs; [
        mysql-workbench # Useful for designing relational table EER Diagrams
        sqlitebrowser   # Useful for examining the database
        code-cursor     # AI powered version of code
      ];

      # Build packages
      # * By calling out both rustc and glibc here I was able to work around a GLIBC versioning 
      #   issue I was seeing related to using rustup to install my rustc system version.
      nativeBuildInputs = with pkgs; [
        bashInteractive # Solve for normal shell operation

        # Rust dependencies
        pkg-config      # System dependency path resolution
        rustc           # Ensure we have Rust 1.86 or newer available
        cargo           # Rust build tooling
        glibc           # System dependency for SQLx macros
        sqlx-cli        # SQLx command line tool

        # Flutter dependencies
        flutter         # Flutter 3.32 or newer
      ];

      # Set flutter and dart SDK locations to get correct versions
      FLUTTER_ROOT="${pkgs.flutter}";
      DART_ROOT="${pkgs.flutter}/bin/cache/dart-sdk";
      CHROME_EXECUTABLE ="${pkgs.chromium}/bin/chromium";

      # Set the rust source path for rust-analyzer to be happy
      RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

      # Launch VSCode in the dev shell
      shellHook = ''
        echo "Launch Cursor for flutter with 'cursor .' or for the api with 'cursor api'"
      '';
    };
  });
}
