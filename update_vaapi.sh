#!/bin/bash

echo "========== Update VAAPI Driver =========="
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
