#!/bin/bash
# Install the aic8800 DKMS driver + firmware for BrosTrend AIC8800-based
# USB Wi-Fi adapters (e.g. AIC8800DC, USB ID 2c4e:0126).
# Tested on Fedora; should work on any distro with dkms + kernel headers.
set -euo pipefail

MODULE=aic8800
VERSION=1.0.9
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST=/usr/src/${MODULE}-${VERSION}

[ "$(id -u)" -eq 0 ] || { echo "Run as root: sudo $0"; exit 1; }

# --- dependencies -----------------------------------------------------------
if ! command -v dkms >/dev/null; then
    echo "dkms not found."
    if command -v dnf >/dev/null; then
        echo "Installing dkms and kernel headers..."
        dnf install -y dkms "kernel-devel-$(uname -r)" || dnf install -y dkms kernel-devel
    else
        echo "Install dkms and your kernel headers, then re-run."
        exit 1
    fi
fi
if [ ! -d "/lib/modules/$(uname -r)/build" ]; then
    echo "Kernel headers for $(uname -r) missing."
    if command -v dnf >/dev/null; then
        dnf install -y "kernel-devel-$(uname -r)" || dnf install -y kernel-devel
    else
        echo "Install kernel headers for $(uname -r), then re-run."
        exit 1
    fi
fi

# --- firmware ---------------------------------------------------------------
echo "Installing firmware to /lib/firmware ..."
cp -a "$SRC_DIR"/firmware/aic8800* /lib/firmware/

# --- driver source into /usr/src -------------------------------------------
if [ -L "$DEST" ] || [ -d "$DEST" ]; then
    echo "$DEST already exists; leaving it in place."
else
    echo "Copying driver source to $DEST ..."
    mkdir -p "$DEST"
    # exclude repo metadata and firmware; DKMS only needs the module source
    (cd "$SRC_DIR" && tar --exclude=.git --exclude=.github --exclude=firmware \
        --exclude=install.sh --exclude=README.md --exclude=LICENSE \
        --exclude=check-upstream.sh --exclude=upstream -cf - .) | tar -xf - -C "$DEST"
fi

# --- dkms build + install ---------------------------------------------------
dkms status "$MODULE/$VERSION" | grep -q . || dkms add "$MODULE/$VERSION"
dkms install "$MODULE/$VERSION" -k "$(uname -r)"

modprobe aic8800_fdrv || true
echo
echo "Done. Plug in the adapter; a wlan interface should appear."
echo "Secure Boot users: enroll the DKMS signing key first:"
echo "  mokutil --import /var/lib/dkms/mok.pub   (then reboot and enroll)"
