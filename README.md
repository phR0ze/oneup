# OneUp

Flutter app for point tracking

### Quick links
* [Backlog](#backlog)
* [Dev Env](#dev-env)
  * [NixOS Dev Shell](#-nixos-dev-shell)
  * [VSCode for Rust API](#vscode-for-rust-api)
  * [VSCode for Flutter UI](#vscode-for-flutter-ui)
  * [flake.nix](#flake-nix)

## Backlog
* [ ] Working API
  * [ ] API docs
* [ ] Integrate API with UI

## Dev Env
The `flake.nix` file in the root of the project provides a development environment that can be set up 
running `nix develop`. The development environment is responsible for providing the correct versions 
of dependencies for this project.

Currently this is a mix of my local system and NixOS requirements for local library lookup, but I 
plan on calling out all the other dependencies eventually.

### NixOS Dev Shell
To recreate the development environment in NixOS you can simply open a shell and run:
```bash
$ cd ~/Projects/oneup
$ nix develop
```

### VSCode for Rust API
Start VSCode to work on the API with:

1. Set up [NixOS Dev Shell](#nixos-dev-shell)

2. Lauch VSCode in that shell with:
   ```bash
   $ cd ~/Projects/oneup
   $ code api
   ```

### VSCode for Flutter UI

1. Set up [NixOS Dev Shell](#nixos-dev-shell)

2. Lauch VSCode in that shell with:
   ```bash
   $ cd ~/Projects/oneup
   $ code flutter
   ```

2. Build and run the flutter UI locally simply press `F5`

3. Flutter might need a clean rebuild in some cases, run:
   ```bash
   $ cd ~/Projects/oneup/flutter
   $ flutter clean
   $ flutter build linux
   ```
