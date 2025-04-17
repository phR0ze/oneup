# oneup

Flutter app for point tracking

## NixOS Dev Env

### Run full-stack locally
1. Start dev terminal with dependency support for the project and launch VSCode
   ```bash
   $ cd ~/Projects/oneup
   $ nix develop
   ```
2. From the dev terminal clean and rebuild flutter app if needed
   ```bash
   $ cd ~/Projects/oneup/flutter
   $ flutter clean
   $ flutter build linux
   ```
3. From the dev terminal launch another VSCode instance for flutter
   1. Press `Ctrl+Shift+n`
   2. Load `~/Projects/oneup/flutter`
   3. Press `F5` to run the flutter project locally

### flake.nix
The `flake.nix` file in the root of the project provides a development environment that can be setup 
running `nix develop`. The development environment is responsible for providing the correct versions 
of dependencies for this project.

Currently this is a mix of my local system and NixOS requirements for local library lookup, but I 
plan on calling out all the other dependencies eventually.
