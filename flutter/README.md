# OneUp Flutter UI

### Quick links
* [NixOS Dev](#nixos-dev)
  * [Launch Cursor](#launch-cursor)
  * [Run as dev linux app](#run-as-dev-linux-app)
  * [Run as dev web app](#run-as-dev-web-app)
* [NixOS Deployment](#nixos-deployment)
  * [Run as web app](#run-as-web-app)
 
## NixOS Dev

### Launch Cursor
To load the development environment and launch Cursor
```bash
$ cd ~/Projects/oneup
$ nix develop
$ cursor flutter
```

### Build and run Server
In order to have something for the frontend to work with we need to build and run the server 
component first.

1. Launch a new shell from the root of the project
   ```bash
   $ nix develop
   ```
2. Switch to the server build
   ```bash
   $ cd server
   $ cargo build
   ```
3. Ensure that your seeded database is present
   ```bash
   $ cp ~/Backup/sqlite.db .
   ```
4. Run the server
   ```bash
   $ ./target/debug/oneup-server
   ```

### Run as dev linux app
1. [Launch Cursor](#launch-cursor)

2. Clean flutter and code generation scripts
   ```bash
   $ flutter clean
   $ dart run build_runner clean
   ```
3. Ensure code generation is up to date 
   ```bash
   $ dart run build_runner build --delete-conflicting-outputs
   ```
4. Build flutter project for linux
   ```bash
   $ flutter build linux
   ```
5. Run the project for testing
   * Press `F5`

### Run as dev web app
1. Check that `Chrome (web)` is recognized by flutter
   ```bash
   $ flutter devices
   Found 2 connected devices:
   Linux (desktop) • linux  • linux-x64      • NixOS 25.05 (Warbler) 6.6.64
   Chrome (web)    • chrome • web-javascript • Chromium 137.0.7151.68
   ```
2. Launch in the listed browser
   ```bash
   $ flutter run -d chrome
   ```

## NixOS Deployment

### Run as web app
Running the server from the same directory as `web`

1. Shutdown the server
   ```bash
   $ TBD
   ```
2. Build the web app for release, which will generate `build/web` then copy to `server/web`
   ```bash
   $ ./deploy.sh
   ```
3. Start the server back up
   ```bash
   $ cd oneup/server
   $ ./target/debug/oneup-server
   ```
