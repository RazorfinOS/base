SUDO := sudo
PODMAN := $(SUDO) podman
BASE_IMAGE := ghcr.io/razorfinos-org/base
VERSION := latest

.PHONY: build push clean

build:
	$(PODMAN) build \
		--network host \
		--security-opt label=disable \
		-f Containerfile \
		-t $(BASE_IMAGE):$(VERSION) \
		.

push:
	$(PODMAN) push $(BASE_IMAGE):$(VERSION)

clean:
	$(PODMAN) rmi $(BASE_IMAGE):$(VERSION) || true

help:
	@echo "Available targets:"
	@echo "  build  - Build the base image"
	@echo "  push   - Push the base image to registry"
	@echo "  clean  - Remove local base image"
	@echo "  help   - Show this help message"
