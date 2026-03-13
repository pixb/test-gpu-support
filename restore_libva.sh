#!/bin/bash

detect_distro() {
    if command -v pacman &> /dev/null; then
        echo "arch"
    elif command -v apt &> /dev/null; then
        echo "debian"
    else
        echo "unknown"
    fi
}

restore_libva_arch() {
    echo "========== Restore libva packages (Arch Linux) =========="
    echo ""

    echo "On Arch Linux, you can downgrade packages using:"
    echo "  sudo pacman -S libva libva-driver-wrapper"
    echo ""
    echo "Or use downgrade from AUR:"
    echo "  yay -S downgrade"
    echo "  downgrade libva"
    echo ""

    echo "Removing testing repository (if added)..."
    sudo rm -f /etc/pacman.conf.d/*.conf 2>/dev/null

    echo ""
    echo "========== Restore complete =========="
}

restore_libva_debian() {
    echo "========== Restore libva packages (Debian) =========="
    echo ""

    echo "Downgrading libva packages to bookworm version..."
    sudo apt install -y libva2=2.17.0-1 libva-drm2=2.17.0-1 libva-x11-2=2.17.0-1 libva-wayland2=2.17.0-1

    echo ""
    echo "Removing testing repository..."
    sudo rm -f /etc/apt/sources.list.d/testing.list

    echo ""
    echo "Updating APT..."
    sudo apt update

    echo ""
    echo "========== Restore complete =========="
}

DISTRO=$(detect_distro)

case "$DISTRO" in
    arch)
        restore_libva_arch
        ;;
    debian)
        restore_libva_debian
        ;;
    *)
        echo "Unknown distribution."
        exit 1
        ;;
esac
