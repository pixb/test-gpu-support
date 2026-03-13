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

update_vaapi_arch() {
    echo "========== Update VAAPI Driver (Arch Linux) =========="
    echo ""

    echo "Installing/updating Intel VAAPI driver..."
    sudo pacman -S --noconfirm intel-media-driver

    echo ""
    echo "Installing/updating libva..."
    sudo pacman -S --noconfirm libva libva-driver-wrapper

    echo ""
    echo "========== Testing VAAPI =========="
    echo ""

    echo "Testing VAAPI with iHD driver..."
    LIBVA_DRIVER_NAME=iHD ffmpeg -hide_banner -vaapi_device /dev/dri/card0 -f lavfi -i testsrc2=duration=2:size=640x480:rate=30 -vf 'format=nv12,hwupload' -c:v h264_vaapi /tmp/test_vaapi.mp4 2>&1 | tail -10

    echo ""
    echo "Testing VAAPI with i965 driver..."
    LIBVA_DRIVER_NAME=i965 ffmpeg -hide_banner -vaapi_device /dev/dri/card0 -f lavfi -i testsrc2=duration=2:size=640x480:rate=30 -vf 'format=nv12,hwupload' -c:v h264_vaapi /tmp/test_vaapi_i965.mp4 2>&1 | tail -10

    echo ""
    echo "========== Done =========="
}

update_vaapi_debian() {
    echo "========== Update VAAPI Driver (Debian) =========="
    echo ""

    echo "Updating package list..."
    sudo apt update

    echo ""
    echo "Installing Intel VAAPI driver from backports..."
    sudo apt install -t bookworm-backports intel-media-va-driver 2>/dev/null || sudo apt install -y intel-media-va-driver-non-free

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
        update_vaapi_arch
        ;;
    debian)
        update_vaapi_debian
        ;;
    *)
        echo "Unknown distribution. Please update VAAPI driver manually."
        exit 1
        ;;
esac