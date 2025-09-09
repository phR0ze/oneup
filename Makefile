RED := $(shell tput setaf 1)
GREEN := $(shell tput setaf 2)
YELLOW := $(shell tput setaf 3)
CYAN := $(shell tput setaf 6)
NC := $(shell tput sgr0)

.PHONY: all fs bin run dive flutter image develop clean clean-images
all: fs

fs: clean _fs
_fs:
	@echo "${CYAN}:: Building the file system for dockerization...${NC}"
	nix build .#fs

dive:
	@echo "${CYAN}:: Load the image result into dive for viewing the fs...${NC}"
	nix-shell -p dive --run "dive --source docker-archive <(gunzip -c result)"

bin: clean _bin
_bin:
	@echo "${CYAN}:: Building the rust binary for dockerization...${NC}"
	nix build .#bin

flutter:
	@echo "${CYAN}:: Building flutter web app (release mode)...${NC}"
	cd flutter && flutter build web --release
	@echo " > Removing old web files..."
	rm -rf server/web
	@echo " > Staging new web files at ${CYAN}server/web${NC}..."
	cp -r flutter/build/web server/web

image: clean _image clean-images
_image:
	@echo "${CYAN}:: Building the docker image...${NC}"
	nix build .#image
	podman load < result

run:
	@echo "${CYAN}:: Running docker image...${NC}"
	podman run --rm -v "$PWD/db:/app/data" -p 8080:80 oneup`

clean:
	@echo "${CYAN}:: Cleaning build cruft...${NC}"
	@echo " > Removing flake.lock..."
	rm -f flake.lock

# Delete all dangling images (with <none> as tag)
clean-images:
	@echo "${CYAN}>> Removing dangling docker images...${NC}"
	@podman images -f "dangling=true" -q | xargs -r podman rmi
