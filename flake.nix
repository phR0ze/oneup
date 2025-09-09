# Standard Rust dev shell with a few extras for SQLx
# - https://nixos.wiki/wiki/Rust
#
# nativeBuildInputs vs buildInputs vs packages
# - for mkShells they are all treated the same
# - [longer explanation](https://discourse.nixos.org/t/use-buildinputs-or-nativebuildinputs-for-nix-shell/8464)
{
  inputs = {
    # nixos-unstable from 2025.08.31
    nixpkgs.url = "github:nixos/nixpkgs/d7600c775f877cd87b4f5a831c28aa94137377aa";
    # flake-utils from 2024.11.13
    flake-utils.url = "github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b";
    # include generated files being ignored by .gitignore.
    # Note: the path is supposed to be absolute, but I'm exploiting a bug where if the flake.lock 
    # file doesn't exist it will for some reason not follow the absolute path rule.
    webDir = { url = "path:./server/web"; flake = false; };
  };
  outputs = { self, nixpkgs, flake-utils, webDir, ... }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    # Run: `nix build .#oneup`
    # Builds the OneUp server project and stores its binary in result/bin/
    bin = pkgs.rustPlatform.buildRustPackage {
      pname = "oneup";
      version = "0.1.0";
      src = pkgs.lib.cleanSource ./server;
      cargoLock = { lockFile = ./server/Cargo.lock; };
      nativeBuildInputs = with pkgs; [ pkg-config ];
      buildInputs = with pkgs; [ openssl sqlite ];
      doCheck = false; # Optional: skip tests if needed
    };

    # Build out the app directory organized as desired and ensure we copy the actual content from the 
    # /nix/store path to get a clean copy else extra /nix/store items will end up in the Docker image
    fs = pkgs.runCommand "oneup-fs" {} ''
      mkdir -p $out/app/data $out/app/web
      cp -L ${bin}/bin/oneup-server $out/app/oneup
      cp -rL ${webDir}/* $out/app/web
    '';
  in
  {
    # Define package targets used with 'nix build .#<TARGET>' syntax
    packages.bin = bin;
    packages.fs = fs; # having a target allows for examining the result locally

    # Run: `nix build .#image`
    packages.image = pkgs.dockerTools.buildImage {
      name = "oneup";
      tag = "latest";
      copyToRoot = pkgs.buildEnv {
        name = "image-root";
        paths = [ fs ];
        pathsToLink = [ "/" ];
      };
      config = {
        Cmd = [ "/app/oneup" ];
        Env = [
          "IP=0.0.0.0"
          "PORT=80"
          "RUST_LOG=debug"
          "WEB_APP_DIR=/oneup/web"
          "DATABASE_URL=sqlite:///app/data/sqlite.db"
        ];
        WorkingDir = "/app";
        Volumes = { "/app/data" = {}; };
        ExposedPorts = { "80/tcp" = {}; };
      };
    };

    # Run `nix develop`
    # Creates a development shell to work from
    devShells.default = pkgs.mkShell {

      # Supporting tooling
      packages = with pkgs; [
        bashInteractive                           # Solve for normal shell operation
        mysql-workbench                           # Useful for designing relational table EER Diagrams
        sqlitebrowser                             # Useful for examining the database
        code-cursor                               # AI powered version of code
        rust-analyzer                             # Rust Analyzer binary
        vscode-extensions.rust-lang.rust-analyzer # Rust Analyzer extension
      ];

      # Build packages
      # * By calling out both rustc and glibc here I was able to work around a GLIBC versioning 
      #   issue I was seeing related to using rustup to install my rustc system version.
      nativeBuildInputs = with pkgs; [
        clang                 # A C language family frontend for LLVM
        lldb                  # Next gen high-performance debugger for Rust
        llvm                  # Compiler infrastructure
        llvmPackages.bintools # Use lld instead of ld

        # Rust dependencies
        pkg-config            # System dependency path resolution
        cargo                 # Rust build tooling
        rustc                 # Ensure we have Rust 1.86 or newer available
        glibc                 # System dependency for SQLx macros
        sqlx-cli              # SQLx command line tool

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
        echo "Launch Cursor for flutter or server with 'cursor flutter' or 'cursor server'"
      '';
    };
  });
}
