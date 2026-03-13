#!/bin/bash

echo "========== Install Required Tools =========="
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
