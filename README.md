# oneup

Flutter app for point tracking

## NixOS Dev Env

Launch a development terminal in which to then run vscode
```bash
$ cd ~/Projects/oneup
$ nix develop
$ vscode api
```

### flake.nix
The `flake.nix` file in the root of the project provides a development environment that can be setup 
running `nix develop`. The development environment is responsible for providing the correct versions 
of dependencies for this project.

Currently this is a mix of my local system and NixOS requirements for local library lookup, but I 
plan on calling out all the other dependencies here as we'll, such as Flutter.
