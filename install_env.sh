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

install_arch() {
    echo "========== Install Required Tools (Arch Linux) =========="
    echo ""

    echo "Updating package database..."
    sudo pacman -Sy --noconfirm

    echo ""
    echo "Installing basic tools..."
    sudo pacman -S --noconfirm coreutils findutils gawk grep util-linux

    echo ""
    echo "Installing video tools..."
    sudo pacman -S --noconfirm ffmpeg libva-utils

    echo ""
    echo "Installing hardware info tools..."
    sudo pacman -S --noconfirm pciutils dmidecode

    echo ""
    echo "Installing Intel GPU drivers (if needed)..."
    sudo pacman -S --noconfirm intel-media-driver 2>/dev/null || echo "Intel media driver not available in repos, may need AUR"

    echo ""
    echo "========== Done =========="
    echo ""
    echo "Testing basic commands..."
    which awk grep lspci ffmpeg vainfo
}

install_debian() {
    echo "========== Install Required Tools (Debian) =========="
    echo ""

    echo "Updating package list..."
    sudo apt update

    echo ""
    echo "Installing basic tools..."
    sudo apt install -y coreutils findutils sed gawk grep util-linux

    echo ""
    echo "Installing video tools..."
    sudo apt install -y ffmpeg vainfo

    echo ""
    echo "Installing hardware info tools..."
    sudo apt install -y pciutils lspci dmidecode

    echo ""
    echo "========== Done =========="
    echo ""
    echo "Testing basic commands..."
    which sed awk grep lspci ffmpeg
}

DISTRO=$(detect_distro)

case "$DISTRO" in
    arch)
        install_arch
        ;;
    debian)
        install_debian
        ;;
    *)
        echo "Unknown distribution. Please install dependencies manually."
        echo "Required: ffmpeg, vainfo, lspci, pciutils, dmidecode"
        exit 1
        ;;
esac