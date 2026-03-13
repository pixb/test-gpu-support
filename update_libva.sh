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

update_libva_arch() {
    echo "========== Update libva for VAAPI support (Arch Linux) =========="
    echo ""

    echo "On Arch Linux, libva is typically updated via system package updates."
    echo "To get the latest version:"
    echo "  sudo pacman -Syu"
    echo ""

    echo "For development versions, consider installing from AUR:"
    echo "  yay -S libva-git"
    echo ""

    echo "========== Testing VAAPI =========="
    echo ""

    echo "Testing VAAPI with iHD driver..."
    LIBVA_DRIVER_NAME=iHD ffmpeg -hide_banner -vaapi_device /dev/dri/card0 -f lavfi -i testsrc2=duration=2:size=640x480:rate=30 -vf 'format=nv12,hwupload' -c:v h264_vaapi /tmp/test_vaapi.mp4 2>&1 | tail -10

    echo ""
    echo "Listing available VAAPI drivers:"
    ls -la /usr/lib/dri/ 2>/dev/null | grep va

    echo ""
    echo "========== Done =========="
}

update_libva_debian() {
    echo "========== Update libva for VAAPI support (Debian) =========="
    echo ""

    echo "Adding Debian testing repository..."
    echo "deb http://mirrors.ustc.edu.cn/debian testing main" | sudo tee /etc/apt/sources.list.d/testing.list > /dev/null

    echo "Updating package list..."
    sudo apt update

    echo ""
    echo "Installing libva from testing..."
    sudo apt install -t testing libva2 libva-drm2 libva-x11-2 libva-wayland2 -y

    echo ""
    echo "========== Testing VAAPI =========="
    echo ""

    echo "Testing VAAPI with iHD driver..."
    LIBVA_DRIVER_NAME=iHD ffmpeg -hide_banner -vaapi_device /dev/dri/card0 -f lavfi -i testsrc2=duration=2:size=640x480:rate=30 -vf 'format=nv12,hwupload' -c:v h264_vaapi /tmp/test_vaapi.mp4 2>&1 | tail -10

    echo ""
    echo "========== Done =========="
}

DISTRO=$(detect_distro)

case "$DISTRO" in
    arch)
        update_libva_arch
        ;;
    debian)
        update_libva_debian
        ;;
    *)
        echo "Unknown distribution. Please update libva manually."
        exit 1
        ;;
esac