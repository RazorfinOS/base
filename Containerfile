FROM docker.io/archlinux/archlinux:latest

ENV DEV_DEPS="base-devel git rust whois"

# Install all packages BEFORE filesystem restructuring to maintain pacman database integrity
RUN pacman -Syyuu --noconfirm \
    base \
    linux \
    linux-firmware \
    systemd \
    dracut \
    ostree \
    btrfs-progs \
    e2fsprogs \
    xfsprogs \
    dosfstools \
    skopeo \
    dbus \
    dbus-glib \
    glib2 \
    shadow \
    ansible \
    sudo \
    zsh \
    curl \
    wget \
    git \
    python \
    python-pip \
    ${DEV_DEPS} && \
    pacman -Sc --noconfirm

# Build and install bootc from source
RUN --mount=type=tmpfs,dst=/tmp --mount=type=tmpfs,dst=/root \
    git clone https://github.com/bootc-dev/bootc.git /tmp/bootc && \
    cd /tmp/bootc && \
    make bin && \
    make install-all && \
    make install-initramfs-dracut && \
    git clone https://github.com/p5/coreos-bootupd.git -b sdboot-support /tmp/bootupd && \
    cd /tmp/bootupd && \
    cargo build --release --bins --features systemd-boot && \
    make install

# Setup a temporary root passwd (changeme) for dev purposes
RUN usermod -p "$(echo "changeme" | mkpasswd -s)" root

# Remove development dependencies we no longer need
RUN pacman -Rns --noconfirm ${DEV_DEPS}

# Generate initramfs
ENV DRACUT_NO_XATTR=1
RUN sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
    dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"'

# Preserve pacman database BEFORE filesystem restructuring
RUN mkdir -p /usr/share/factory/var/lib && \
    cp -a /var/lib/pacman /usr/share/factory/var/lib/

# Restructure filesystem for bootc/ostree
RUN rm -rf /var /boot /home /root /usr/local /srv && \
    mkdir -p /var /boot /sysroot && \
    ln -s /var/home /home && \
    ln -s /var/roothome /root && \
    ln -s /var/srv /srv && \
    ln -s sysroot/ostree ostree && \
    ln -s /var/usrlocal /usr/local

# Restore pacman database after filesystem restructuring
RUN mkdir -p /var/lib && \
    cp -a /usr/share/factory/var/lib/pacman /var/lib/

# Update useradd default to /var/home instead of /home for User Creation
RUN sed -i 's|^HOME=.*|HOME=/var/home|' "/etc/default/useradd"

# Necessary for `bootc install`
RUN mkdir -p /usr/lib/ostree && \
    printf  "[composefs]\nenabled = yes\n[sysroot]\nreadonly = true\n" | \
    tee "/usr/lib/ostree/prepare-root.conf"

# Validate the container is properly configured for bootc
RUN bootc container lint

LABEL containers.bootc=1
