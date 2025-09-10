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
* [Dev Env](#dev-env)
  * [NixOS Dev Shell](#-nixos-dev-shell)
  * [Cursor for Rust Server](#cursor-for-rust-server)
  * [Cursor for Flutter UI](#cursor-for-flutter-ui)
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
$ make flutter
$ make image
```

### Run docker image
```bash
$ make run
```

### Publish docker image
1. Create a Personal Access Token (PAT) in Github
   1. Navigate to `USER >Settings >Developer settings >Personal access tokens >Tokens (classic)`
   2. Click on `Generate new token`
   3. Select `Generate new token (classic)`
   4. Name the token e.g. `Packaging`
   5. Set an expiration for your token
   6. Select the `write:packages` scope
   7. Click `Generate token` at the bottom of the page

2. Login to the Github's Container Registry (GHCR)
   ```bash
   $ echo "<YOUR_PAT>" | podman login ghcr.io -u your-username --password-stdin
   ```

3. Build and publish the image
   ```bash
   $ make flutter
   $ make image
   $ make publish
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

### Cursor for Rust API
Start Cursor to work on the API with:

1. Set up [NixOS Dev Shell](#nixos-dev-shell)

2. Lauch Cursor in that shell with:
   ```bash
   $ cd ~/Projects/oneup
   $ cursor server
   ```

### Cursor for Flutter UI

1. Set up [NixOS Dev Shell](#nixos-dev-shell)

2. Lauch Cursor in that shell with:
   ```bash
   $ cd ~/Projects/oneup
   $ cursor flutter
   ```

2. Build and run the flutter UI locally simply press `F5`

3. Flutter might need a clean rebuild in some cases, run:
   ```bash
   $ cd ~/Projects/oneup/flutter
   $ flutter clean
   $ flutter build linux
   ```
