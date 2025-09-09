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
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    # Run: `nix build .#oneup`
    # Builds the OneUp server project and stores its binary in result/bin/
    oneup = pkgs.rustPlatform.buildRustPackage {
      pname = "oneup";
      version = "0.1.0";
      src = ./server;
      cargoLock = { lockFile = ./server/Cargo.lock; };
      nativeBuildInputs = with pkgs; [ pkg-config ];
      buildInputs = with pkgs; [ openssl sqlite ];
      doCheck = false; # Optional: skip tests if needed
    };
  in
  {
    # Run: `nix build .#image`
    # Load the docker image: `podman load < result`
    # Run the docker image: `podman run --rm -v "$PWD/db:/oneup/data" -p 8080:80 oneup`
    # Examine docker contents: `dive --source docker-archive <(gunzip -c result)`
    #rootfs = pkgs.runCommand "oneup-rootfs" {} ''
    #  mkdir -p $out/app
    #'';
    packages.image = pkgs.dockerTools.buildImage {
      name = "oneup";
      tag = "latest";
      copyToRoot = pkgs.buildEnv {
        name = "image-root";
        paths = [
          oneup
        ];

        # creates nix store link from oneup
        pathsToLink = [ "/bin" ];
      };
      extraCommands = ''
        mkdir -p ./oneup/data ./oneup/web
        cp ./bin/oneup-server ./oneup/oneup
      '';
      config = {
        Cmd = [ "/oneup/oneup" ];
        Env = [
          "IP=0.0.0.0"
          "PORT=80"
          "RUST_LOG=debug"
          "DATABASE_URL=sqlite:///oneup/data/sqlite.db"
        ];
        WorkingDir = "/oneup";
        Volumes = { "/oneup/data" = {}; }; # create potential mount point
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

    # Define package targets used with 'nix build .#<TARGET>' syntax
    packages.oneup = oneup;
  });
}
