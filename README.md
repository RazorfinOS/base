# Razorfin Base Image

This repository contains the base image for razorfin that provides a clean, properly configured Arch Linux bootc environment.

## Purpose

This base image solves the pacman database synchronization issues that occur when using third-party bootc images. It ensures:

- All packages are properly tracked in the pacman database
- No orphaned files that cause `--overwrite` conflicts
- Pre-installed common dependencies for faster razorfin builds
- Clean bootc/ostree filesystem structure

## Building the Base Image

### Prerequisites
- Podman with root access
- Network connectivity for package downloads

### Build Process

```bash
# Build the base image
make build

# Push to registry (requires authentication)
make push

# Clean up local image
make clean
```

### Manual Build

```bash
sudo podman build \
    --network host \
    --security-opt label=disable \
    -f Containerfile \
    -t ghcr.io/razorfinos-org/base:latest \
    .
```

## Using the Base Image

The Razorfin project is configured to use this base image by default. Images are available from GitHub Container Registry:

```bash
# Pull the latest image
podman pull ghcr.io/<owner>/base:latest

# Or use in a Containerfile
FROM ghcr.io/<owner>/base:latest
```

### Verifying Image Signatures

All images pushed to the registry are signed with cosign. To verify the signature:

```bash
# Verify using the public key in this repository
cosign verify --key cosign.pub ghcr.io/<owner>/base:latest
```

To build Razorfin variants:

```bash
make image VARIANT=stable
```

## Package Contents

The base image includes:

### Core System
- `base` - Arch Linux base system
- `linux` + `linux-firmware` - Kernel and firmware
- `systemd` - System and service manager
- `dracut` - Initramfs generation

### Bootc Components
- `bootc` - Built from source with composefs support
- `bootupd` - Boot loader management
- `ostree` - OSTree filesystem management

### Common Tools
- `ansible` - Configuration management
- `git` - Version control
- `sudo` - Privilege escalation
- `zsh` - Shell
- `curl`, `wget` - HTTP clients
- `python`, `python-pip` - Python runtime

### Development Tools (removed after bootc build)
- `base-devel` - Build essentials
- `rust` - Rust compiler for bootc
- Various build dependencies

## Filesystem Structure

The image implements the bootc/ostree filesystem layout:

- `/var/home` → `/home` (symlink)
- `/var/roothome` → `/root` (symlink)
- `/var/srv` → `/srv` (symlink)
- `/var/usrlocal` → `/usr/local` (symlink)
- `/sysroot/ostree` → `/ostree` (symlink)

## Database Preservation

The pacman database is preserved through the filesystem restructuring process:

1. Packages installed to standard filesystem
2. Database copied to `/usr/share/factory/var/lib/pacman`
3. Filesystem restructured for bootc
4. Database restored to `/var/lib/pacman`

This ensures all package files are properly tracked without conflicts.

## Maintenance

### Updating the Base Image

When Arch Linux packages need updates or new dependencies are required:

1. Update the `Containerfile`
2. Build and test locally
3. Push to registry
4. Update razorfin builds to use new version

### Version Management

Consider using date-based tags for production:

```bash
# Build with date tag
sudo podman build -t ghcr.io/razorfinos-org/base:2025.10 .
sudo podman tag ghcr.io/razorfinos-org/base:2025.10 ghcr.io/razorfinos-org/base:latest
```

## Troubleshooting

### Build Failures

- **Network issues**: Ensure host networking is enabled
- **Permission errors**: Verify podman root access
- **Rust build failures**: May need more memory/disk space

### Package Conflicts

If package conflicts occur during base image build:
1. The packages are likely incompatible
2. Check Arch Linux package updates
3. Consider removing conflicting packages
