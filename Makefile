RED := $(shell tput setaf 1)
GREEN := $(shell tput setaf 2)
YELLOW := $(shell tput setaf 3)
CYAN := $(shell tput setaf 6)
NC := $(shell tput sgr0)
PROJECT_PATH := $(shell pwd)

.PHONY: all fs bin run dive flutter image develop flake clean clean-images
all: fs

fs: flake _fs
_fs:
	@echo "$(CYAN):: Building the file system for dockerization...$(NC)"
	nix build .#fs

dive:
	@echo "$(CYAN):: Load the image result into dive for viewing the fs...$(NC)"
	nix-shell -p dive --run "dive --source docker-archive <(gunzip -c result)"

bin: flake _bin
_bin:
	@echo "$(CYAN):: Building the rust binary for dockerization...$(NC)"
	nix build .#bin

flutter:
	@echo "$(CYAN):: Building flutter web app (release mode)...$(NC)"
	cd flutter && flutter build web --release
	@echo " > Removing old web files..."
	rm -rf server/web
	@echo " > Staging new web files at $(CYAN)server/web$(NC)..."
	cp -r flutter/build/web server/web

image: flake _image clean-images
_image:
	@echo "$(CYAN):: Building the docker image...$(NC)"
	nix build .#image
	podman load < result

run:
	@echo "$(CYAN):: Running docker image...$(NC)"
	podman run --rm -v "$$(pwd)/db:/app/data" -p 8080:80 oneup

flake:
	@echo "$(CYAN):: Patch the flake with project directory...$(NC)"
	@sed -i 's|PROJECT_PATH|$(PROJECT_PATH)|g' flake.nix

clean:
	@echo "$(CYAN):: Removing build cruft...$(NC)"
	@echo " > Removing flake path injection changes..."
	@git checkout -- flake.nix flake.lock

clean-images:
	@echo "$(CYAN):: Removing dangling docker images...$(NC)"
	@podman images -f "dangling=true" -q | xargs -r podman rmi
