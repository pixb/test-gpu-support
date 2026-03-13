#!/bin/bash

INTEL_VGA_IDS="8086"

echo "========== Hardware Information =========="
echo ""

echo "--- CPU Info ---"
if command -v lscpu &> /dev/null; then
    lscpu | grep -E "Model name|CPU\(s\)|Thread|Core|Socket"
elif command -v sysctl &> /dev/null; then
    sysctl -n machdep.cpu.brand_string 2>/dev/null || sysctl -n hw.model
elif [ -f /proc/cpuinfo ]; then
    grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | xargs
fi
echo ""

echo "--- Memory ---"
if command -v free &> /dev/null; then
    free -h
elif command -v vm_stat &> /dev/null; then
    vm_stat
elif command -v system_profiler &> /dev/null; then
    system_profiler SPHardwareDataType | grep -E "Memory|Physical"
fi
echo ""

echo "--- GPU Info ---"
if command -v nvidia-smi &> /dev/null; then
    echo "--- NVIDIA GPU ---"
    nvidia-smi --query-gpu=name,driver_version,memory.total,compute_cap --format=csv
elif command -v rocm-smi &> /dev/null; then
    echo "--- AMD GPU (ROCm) ---"
    rocm-smi --showproductname --showtemp --showutilization --showvoltage
elif command -v system_profiler &> /dev/null; then
    system_profiler SPDisplaysDataType
    echo "--- Apple GPU (Metal) ---"
    system_profiler SPDisplaysDataType | grep -E "Chipset|Metal"
fi
echo ""

echo "--- PCI VGA/Display Devices ---"
echo "All VGA compatible controllers:"
lspci -nn 2>/dev/null | grep -E "VGA|Display" || echo "  None found"
echo ""

echo "--- Intel GPU Detection (by PCI ID) ---"
echo "Intel GPU generations (vendor: 8086):"
echo "  Skylake (6th gen):    1912, 191d, 191e, 191b"
echo "  Kaby Lake (7th gen):  5912, 5916, 5917, 5912"
echo "  Coffee Lake (8th):    3e71, 3e91, 3e92, 3e99"
echo "  Comet Lake (10th):    9b41, 9b42, 9b21"
echo "  Ice Lake (10th):      8a51, 8a70"
echo "  Tiger Lake (11th):    9a49, 9a60"
echo "  Alder Lake (12th):    4680, 4682, 4690"
echo "  Rocket Lake (11th):   4c8a, 4c8b"
echo "  Meteor Lake (14th):   7d55, 7d67"
echo "  Lunar Lake (18th):    7d14, 7d72"
echo ""
echo "Detected Intel GPUs:"
lspci -nn 2>/dev/null | grep VGA | grep 8086 | head -5 || echo "  None"
echo ""

echo "--- DRI Devices ---"
echo "Available DRI devices:"
ls -la /dev/dri/ 2>/dev/null | grep -v "^total\|^d" || echo "  No DRI devices"
echo ""
echo "DRI by-path mapping:"
for path in /dev/dri/by-path/pci-*; do
    if [ -e "$path" ]; then
        filename=$(basename "$path")
        if [[ "$filename" == *"-card" ]]; then
            TARGET=$(readlink -f "$path" 2>/dev/null)
            PCI_ADDR=$(echo "$path" | cut -d/ -f5 | cut -d- -f2)
            while [[ "$PCI_ADDR" == 0* ]]; do
                PCI_ADDR="${PCI_ADDR#0}"
            done
            if [[ "$PCI_ADDR" == :* ]]; then
                PCI_ADDR="${PCI_ADDR#:}"
            fi
            PCI_INFO=$(lspci -nn 2>/dev/null | grep "$PCI_ADDR" | head -1)
            echo "  $TARGET -> $PCI_INFO"
        fi
    fi
done
echo ""

echo "--- Hardware Video Encoders (FFmpeg) ---"
if command -v ffmpeg &> /dev/null; then
    echo "Available HW encoders:"
    ffmpeg -hide_banner -codecs 2>&1 | grep -E "h264_(nvenc|amf|videotoolbox|qsv|vaapi)|hevc_(nvenc|amf|videotoolbox|qsv|vaapi)" | head -10
fi
echo ""

echo "--- VAAPI / Video Acceleration Info ---"
echo "Testing VAAPI devices..."

if [ -d /dev/dri ]; then
    for card in /dev/dri/card*; do
        if [ -c "$card" ]; then
            echo ""
            echo "Testing $card with iHD driver:"
            LIBVA_DRIVER_NAME=iHD ffmpeg -hide_banner -vaapi_device "$card" -f lavfi -i testsrc=duration=1:size=320x240:rate=1 -frames:v 1 -f null - 2>&1 | grep -E "frame|failed|Error|success" | head -3
        fi
    done
fi

echo ""
echo "--- OS Info ---"
if command -v uname &> /dev/null; then
    uname -a
fi
if command -v sw_vers &> /dev/null; then
    sw_vers
fi
echo ""

echo "--- Available Video Codecs (FFmpeg) ---"
if command -v ffmpeg &> /dev/null; then
    ffmpeg -hide_banner -codecs 2>/dev/null | grep -E "D.*(h264|hevc|av1|nv|h265|vp9)" | head -20
fi
echo ""

echo "========== Hardware Info Complete =========="
