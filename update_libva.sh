#!/bin/bash

echo "========== Update libva for VAAPI support =========="
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
