set shell := ["bash", "-c"]

red := `tput setaf 1`
green := `tput setaf 2`
yellow := `tput setaf 3`
cyan := `tput setaf 6`
nc   := `tput sgr0`
project_path := `pwd`

# Build the file system for dockerization
default: fs

# Build the file system for dockerization
fs: flake _fs clean

_fs:
    @echo "{{cyan}}:: Building the file system for dockerization...{{nc}}"
    nix build .#fs

# Load the image result into dive for viewing the fs
dive:
    @echo "{{cyan}}:: Load the image result into dive for viewing the fs...{{nc}}"
    nix-shell -p dive --run "dive --source docker-archive <(gunzip -c result)"

# Build the rust binary for dockerization
bin: flake _bin

_bin:
    @echo "{{cyan}}:: Building the rust binary for dockerization...{{nc}}"
    nix build .#bin

# Build flutter web app (release mode) and stage to server/web
flutter:
    @echo "{{cyan}}:: Building flutter web app (release mode)...{{nc}}"
    cd flutter && flutter build web --release
    @echo " > Removing old web files..."
    rm -rf server/web
    @echo " > Staging new web files at {{cyan}}server/web{{nc}}..."
    cp -r flutter/build/web server/web

# Build the docker image
image: flake _image clean clean-images

_image:
    @echo "{{cyan}}:: Building the docker image...{{nc}}"
    nix build .#image
    podman load < result

# Publish image to ghcr.io
publish:
    @echo "{{cyan}}:: Publishing image on Github...{{nc}}"
    @echo " > Tagging image for Github..."
    podman tag oneup ghcr.io/phr0ze/oneup:latest
    podman push ghcr.io/phr0ze/oneup:latest

# Run the app: just run [dev-server|dev-chrome|dev-mobile] (no arg runs docker image)
run target='':
    #!/usr/bin/env bash
    case "{{target}}" in
      dev-server)
        echo "{{cyan}}:: Running server locally...{{nc}}"
        cd server && cargo run
        ;;
      dev-chrome)
        echo "{{cyan}}:: Running flutter dev server with hot reload in Chrome...{{nc}}"
        cd flutter && flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
        ;;
      dev-mobile)
        echo "{{cyan}}:: Running flutter Linux desktop at mobile size (345x673)...{{nc}}"
        cd flutter && ONEUP_MOBILE=1 flutter run -d linux
        ;;
      '')
        echo "{{cyan}}:: Running docker image...{{nc}}"
        podman run --rm -v "{{project_path}}/db:/app/data" -p 8080:80 oneup
        ;;
      *)
        echo "Unknown target: {{target}}"
        echo "Usage: just run [dev-server|dev-chrome|dev-mobile]"
        exit 1
        ;;
    esac

# Patch the flake with project directory
flake:
    @echo "{{cyan}}:: Patch the flake with project directory...{{nc}}"
    sed -i 's|PROJECT_PATH|{{project_path}}|g' flake.nix

# Remove build cruft and revert flake changes
clean:
    @echo "{{cyan}}:: Removing build cruft...{{nc}}"
    @echo " > Removing flake path injection changes..."
    git checkout -- flake.nix flake.lock

# Remove dangling docker images
clean-images:
    @echo "{{cyan}}:: Removing dangling docker images...{{nc}}"
    podman images -f "dangling=true" -q | xargs -r podman rmi
