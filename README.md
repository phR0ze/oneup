# OneUp

Flutter app for point tracking

### Quick links
* [Overview](#overview)
* [NixOS Dev Env](#nixos-dev-env)
  * [Local full-stack](#local-full-stack)
  * [flake.nix](#flake-nix)

## NixOS Dev Env

### Local full-stack
For development you often want to be able to not only build but run the full project locally.

1. Start dev terminal with dependency support for the project and launch VSCode for the API
   ```bash
   $ cd ~/Projects/oneup
   $ nix develop
   ```

2. An additional VSCode instance can be started for flutter UI dev
   1. Press `Ctrl+Shift+n`
   2. Load `~/Projects/oneup/flutter`
   3. Press `F5` to run the flutter project locally

3. Flutter might need a fclean rebuild in some cases
   ```bash
   $ cd ~/Projects/oneup/flutter
   $ flutter clean
   $ flutter build linux
   ```

### flake.nix
The `flake.nix` file in the root of the project provides a development environment that can be setup 
running `nix develop`. The development environment is responsible for providing the correct versions 
of dependencies for this project.

Currently this is a mix of my local system and NixOS requirements for local library lookup, but I 
plan on calling out all the other dependencies eventually.
