#!/bin/bash

echo "========== Restore libva packages =========="
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
