#!/bin/bash

set -euo pipefail

# Configuration
BASE_IMAGE="ghcr.io/razorfinos-org/base"
VERSION="${VERSION:-latest}"
REGISTRY="${REGISTRY:-ghcr.io}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v podman &> /dev/null; then
        log_error "Podman is not installed or not in PATH"
        exit 1
    fi

    if ! podman system info &> /dev/null; then
        log_error "Cannot connect to Podman. Make sure Podman is running and you have proper permissions."
        exit 1
    fi

    log_success "Prerequisites check passed"
}

# Build the base image
build_image() {
    log_info "Building base image: ${BASE_IMAGE}:${VERSION}"

    sudo podman build \
        --network host \
        --security-opt label=disable \
        -f Containerfile \
        -t "${BASE_IMAGE}:${VERSION}" \
        .

    log_success "Base image built successfully"
}

# Test the image
test_image() {
    log_info "Testing the built image..."

    # Basic validation - check if the image can run bootc container lint
    if sudo podman run --rm "${BASE_IMAGE}:${VERSION}" bootc container lint; then
        log_success "Image validation passed"
    else
        log_error "Image validation failed"
        exit 1
    fi
}

# Push image to registry
push_image() {
    if [[ "${PUSH:-false}" == "true" ]]; then
        log_info "Pushing image to registry..."

        sudo podman push "${BASE_IMAGE}:${VERSION}"
        log_success "Image pushed to registry"
    else
        log_info "Skipping push (set PUSH=true to enable)"
    fi
}

# Main execution
main() {
    log_info "Starting razorfin bootc base image build"
    log_info "Image: ${BASE_IMAGE}:${VERSION}"

    check_prerequisites
    build_image
    test_image
    push_image

    log_success "Build process completed successfully!"
    log_info "To use this image, ensure razorfin Containerfile references: ${BASE_IMAGE}:${VERSION}"
}

# Show usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Build the razorfin bootc base image.

Environment Variables:
    VERSION     Image version tag (default: latest)
    PUSH        Set to 'true' to push to registry (default: false)
    REGISTRY    Container registry (default: ghcr.io)

Examples:
    # Build with default settings
    ./scripts/build.sh

    # Build specific version
    VERSION=2024.11 ./scripts/build.sh

    # Build and push to registry
    PUSH=true ./scripts/build.sh

    # Build with date tag and push
    VERSION=\$(date +%Y.%m) PUSH=true ./scripts/build.sh

EOF
}

# Handle command line arguments
case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    *)
        main
        ;;
esac
