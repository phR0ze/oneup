# OneUp

Flutter app for point tracking

### Quick links
* [Backlog](#backlog)
  * [Next](#next)
  * [Sometime](#sometime)
* [User Journeys](#user-journeys)
  * [First run login](#first-run-login)
* [Deployment](#deployment)
  * [Build docker image](#build-docker-image)
  * [Run docker image](#run-docker-image)
  * [Publish docker image](#publish-docker-image)
  * [Deploy with Nix](#deploy-with-nix)
* [Dev Env](#dev-env)
  * [NixOS Dev Shell](#-nixos-dev-shell)
  * [Claude Dev](#claude-dev)
  * [VSCode for Rust Server](#vscode-for-rust-server)
  * [VSCode for Flutter UI](#vscode-for-flutter-ui)
  * [flake.nix](#flake-nix)

## Backlog

### Next
* Add points editor for admin
* Fix negative values showing up as green occassionally
* Add user profile image support

### Sometime
* Harden CORS
* API is not logging requests
* Audit log when and what
* API Swagger specification
* Support running locally only without server

## User Journeys

### First run login
The first time the user runs the client application they will be presented with an option to choose 
the type of deployment they would like: local storage or using backend server for storage.

1. 

## Deployment

### Build docker image
```bash
$ just flutter
$ just image
```

### Run docker image
```bash
$ just run
```

### Publish docker image
1. [Create a Personal Access Token (PAT) in Github](https://github.com/phR0ze/tech-docs/blob/main/src/development/version_control/github/README.md#create-pat-for-ghcr)

2. [Log into the GHCR](https://github.com/phR0ze/tech-docs/blob/main/src/development/version_control/github/README.md#log-into-the-ghcr)

3. Build and publish the image
   ```bash
   $ just flutter
   $ just image
   $ just publish
   ```

### Deploy with Nix
Deploy using the NixOS OCI container module from [nixos-config](https://github.com/phR0ze/nixos-config/blob/main/options/services/oci/oneup).
The module creates a dedicated user, an isolated podman network, and a persistent data directory at
`/var/lib/oneup/data` mapped to `/app/data` inside the container.

The service listens on port `2002` by default (host-side) and forwards to port `8080` in the
container. Override with `services.oci.oneup.port = <port>;` in your config.

1. Push changes to github
   ```bash
   git push origin main
   ```

2. [Publish docker image](#publish-docker-image)


3. Enable the service
   ```nix
   services.oci.oneup = { enable = true; port = 8002; };
   ```

4. Apply the configuration:
   ```bash
   sudo ./clu update system
   ```

5. Verify the service is running:
   ```bash
   sudo systemctl status podman-oneup
   ```

6. Upgrade the image being used to latest
   ```bash
   sudo podman pull ghcr.io/phr0ze/oneup:latest
   sudo systemctl restart podman-oneup
   ```

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

### Claude Dev
Start Claude from the `~/Projects/oneup` directory

1. Set up a new shell to run the server
   1. First [NixOS Dev Shell](#nixos-dev-shell)
   2. Run: `just run dev-server`

2. Set up a new shell to run the UI in Chrome
   1. First [NixOS Dev Shell](#nixos-dev-shell)
   2. Run: `just run dev-chrome`

### VSCode Rust API
Start vscode to work on the API with:

1. Set up [NixOS Dev Shell](#nixos-dev-shell)

2. Lauch VSCode in that shell with:
   ```bash
   $ cd ~/Projects/oneup
   $ code server
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
