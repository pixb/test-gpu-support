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

restore_arch() {
    echo "========== Restore pacman configuration (Arch Linux) =========="
    echo ""

    BACKUP_FILE=$(ls -t /etc/pacman.conf.backup_* 2>/dev/null | head -1)

    if [ -z "$BACKUP_FILE" ]; then
        echo "No backup file found!"
        exit 1
    fi

    echo "Found backup: $BACKUP_FILE"
    echo "Restoring..."
    sudo cp "$BACKUP_FILE" /etc/pacman.conf

    echo ""
    echo "========== Restore complete =========="
}

restore_debian() {
    echo "========== Restore APT sources (Debian) =========="
    echo ""

    BACKUP_FILE=$(ls -t /etc/apt/sources.list.backup_* 2>/dev/null | head -1)

    if [ -z "$BACKUP_FILE" ]; then
        echo "No backup file found!"
        exit 1
    fi

    echo "Found backup: $BACKUP_FILE"
    echo "Restoring..."
    sudo cp "$BACKUP_FILE" /etc/apt/sources.list

    echo ""
    echo "Updating APT..."
    sudo apt update

    echo ""
    echo "========== Restore complete =========="
}

DISTRO=$(detect_distro)

case "$DISTRO" in
    arch)
        restore_arch
        ;;
    debian)
        restore_debian
        ;;
    *)
        echo "Unknown distribution."
        exit 1
        ;;
esac
