# OneUp Flutter UI

### Quick links
* [Overview](#overview)
  * [NixOS Dev Env](#nixos-dev-env)
 
## Overview

### NixOS Dev Env
1. [Launch VSCode for Flutter UI](../README.md#vscode-for-flutter-ui)

2. Build and run the flutter UI
   1. First generate freezed components
      ```bash
      $ dart run build_runner build --delete-conflicting-outputs

      # Alternatively 
      $ flutter pub run build_runner clean
      $ flutter pub run build_runner build --delete-conflicting-outputs
      ```
   2. Press `F5`

3. Flutter might need a clean rebuild in some cases, run:
   ```bash
   $ cd ~/Projects/oneup/flutter
   $ flutter clean
   $ flutter build linux
   ```
