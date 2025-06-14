# OneUp Flutter UI

### Quick links
* [NixOS Dev](#nixos-dev)
  * [Launch Cursor](#launch-cursor)
  * [Fresh rebuild](#fresh-rebuild)
 
## NixOS Dev

### Launch Cursor
To load the development environment and launch Cursor
```bash
$ cd ~/Projects/oneup
$ nix develop
$ cursor flutter
```

### Fresh rebuild
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

