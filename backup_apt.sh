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

backup_arch() {
    echo "========== Backup pacman configuration (Arch Linux) =========="
    echo ""

    if [ -f /etc/pacman.conf ]; then
        BACKUP_FILE="/etc/pacman.conf.backup_$(date +%Y%m%d_%H%M%S)"
        echo "Current pacman.conf:"
        head -20 /etc/pacman.conf

        echo ""
        echo "Backing up to $BACKUP_FILE..."
        sudo cp /etc/pacman.conf "$BACKUP_FILE"

        echo ""
        echo "Backup complete!"
        echo "To restore, run:"
        echo "  sudo cp $BACKUP_FILE /etc/pacman.conf"
    else
        echo "pacman.conf not found."
    fi
}

backup_debian() {
    echo "========== Backup APT sources (Debian) =========="
    echo ""

    BACKUP_FILE="/etc/apt/sources.list.backup_$(date +%Y%m%d_%H%M%S)"

    echo "Current APT sources:"
    cat /etc/apt/sources.list

    echo ""
    echo "Backing up to $BACKUP_FILE..."
    sudo cp /etc/apt/sources.list "$BACKUP_FILE"

    echo ""
    echo "Backup complete!"
    echo "To restore, run:"
    echo "  sudo cp $BACKUP_FILE /etc/apt/sources.list"
    echo "  sudo apt update"
}

DISTRO=$(detect_distro)

case "$DISTRO" in
    arch)
        backup_arch
        ;;
    debian)
        backup_debian
        ;;
    *)
        echo "Unknown distribution."
        exit 1
        ;;
esac
