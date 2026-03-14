#!/bin/bash

INPUT_FILE="test.mp4"
OUTPUT_DIR="output"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: $INPUT_FILE not found!"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "========== GPU Transcode Test =========="
echo "Input: $INPUT_FILE"
echo ""

check_ffmpeg() {
    if ! command -v ffmpeg &> /dev/null; then
        echo "Error: ffmpeg not found!"
        exit 1
    fi
}

check_vaapi_encoders() {
    if [ -z "$VAAPI_DEVICE" ]; then
        return 1
    fi
    
    local profile=$1
    if LIBVA_DRIVER_NAME=iHD vainfo --display drm --device "$VAAPI_DEVICE" 2>&1 | grep -q "$profile.*VAEntrypointEnc"; then
        return 0
    fi
    return 1
}

test_transcode() {
    local encoder=$1
    local output_name=$2
    local description=$3
    
    echo "--- Testing: $encoder ($description) ---"
    local output_file="$OUTPUT_DIR/${INPUT_FILE%.mp4}_${output_name}.mp4"
    
    if ffmpeg -hide_banner -y -i "$INPUT_FILE" -t 10 -c:v "$encoder" -c:a copy "$output_file" 2>&1 | tail -5; then
        if [ -f "$output_file" ]; then
            local size=$(du -h "$output_file" | cut -f1)
            echo "Output: $output_file ($size)"
            echo "Status: SUCCESS"
        fi
    else
        echo "Status: FAILED"
    fi
    echo ""
}

check_ffmpeg

echo "--- Detecting GPU / Hardware Acceleration ---"
if nvidia-smi &> /dev/null; then
    echo "NVIDIA GPU detected"
    GPU_TYPE="nvidia"
elif rocm-smi &> /dev/null; then
    echo "AMD GPU (ROCm) detected"
    GPU_TYPE="amd"
elif ffmpeg -hide_banner -codecs 2>&1 | grep -q "h264_videotoolbox"; then
    echo "Apple Silicon / VideoToolbox detected (macOS hardware acceleration)"
    GPU_TYPE="videotoolbox"
elif [ -d /dev/dri ]; then
    INTEL_DEV=""
    for path in /dev/dri/by-path/pci-*; do
        if [ -e "$path" ]; then
            filename=$(basename "$path")
            if [[ "$filename" == *"-card" ]]; then
                PCI_DEV=$(echo "$path" | cut -d/ -f5 | cut -d- -f2)
                while [[ "$PCI_DEV" == 0* ]]; do
                    PCI_DEV="${PCI_DEV#0}"
                done
                if [[ "$PCI_DEV" == :* ]]; then
                    PCI_DEV="${PCI_DEV#:}"
                fi
                if lspci -nn 2>/dev/null | grep -q "$PCI_DEV.*8086"; then
                    INTEL_DEV=$(readlink -f "$path")
                    break
                fi
            fi
        fi
    done
    if [ -z "$INTEL_DEV" ] && [ -e /dev/dri/card1 ]; then
        INTEL_DEV="/dev/dri/card1"
    fi
    if [ -n "$INTEL_DEV" ]; then
        echo "Intel GPU (VAAPI) detected: $INTEL_DEV"
        GPU_TYPE="vaapi"
        VAAPI_DEVICE="$INTEL_DEV"
    else
        echo "No GPU hardware acceleration detected, using CPU"
        GPU_TYPE="cpu"
    fi
elif ffmpeg -hide_banner -codecs 2>&1 | grep -q "h264_qsv"; then
    echo "Intel Quick Sync detected"
    GPU_TYPE="qsv"
else
    echo "No GPU hardware acceleration detected, using CPU"
    GPU_TYPE="cpu"
fi
echo ""

echo "--- Checking available hardware encoders ---"
ffmpeg -hide_banner -codecs 2>&1 | grep -E "h264_(nvenc|amf|videotoolbox|qsv)|hevc_(nvenc|amf|videotoolbox|qsv)" | head -10
echo ""

echo "--- Test 1: CPU (libx264) ---"
test_transcode "libx264" "cpu" "Software encoding"

if [ "$GPU_TYPE" = "nvidia" ]; then
    echo "--- Test 2: NVIDIA H.264 (h264_nvenc) ---"
    test_transcode "h264_nvenc" "nvidia_h264" "NVIDIA H.264"
    
    echo "--- Test 3: NVIDIA H.265 (hevc_nvenc) ---"
    test_transcode "hevc_nvenc" "nvidia_h265" "NVIDIA H.265"
    
    echo "--- Test 4: NVIDIA H.264 with GPU preset ---"
    ffmpeg -hide_banner -y -i "$INPUT_FILE" -t 10 -c:v h264_nvenc -preset p7 -c:a copy "$OUTPUT_DIR/${INPUT_FILE%.mp4}_nvidia_h264_fast.mp4" 2>&1 | tail -3
    
elif [ "$GPU_TYPE" = "amd" ]; then
    echo "--- Test 2: AMD H.264 (h264_amf) ---"
    test_transcode "h264_amf" "amd_h264" "AMD H.264"
    
    echo "--- Test 3: AMD H.265 (hevc_amf) ---"
    test_transcode "hevc_amf" "amd_h265" "AMD H.265"

elif [ "$GPU_TYPE" = "videotoolbox" ]; then
    echo "--- Test 2: VideoToolbox H.264 (h264_videotoolbox) ---"
    test_transcode "h264_videotoolbox" "vt_h264" "Apple VideoToolbox H.264"
    
    echo "--- Test 3: VideoToolbox H.265/HEVC (hevc_videotoolbox) ---"
    test_transcode "hevc_videotoolbox" "vt_h265" "Apple VideoToolbox H.265"

elif [ "$GPU_TYPE" = "qsv" ]; then
    echo "--- Test 2: Intel Quick Sync H.264 (h264_qsv) ---"
    test_transcode "h264_qsv" "qsv_h264" "Intel Quick Sync H.264"
    
    echo "--- Test 3: Intel Quick Sync H.265 (hevc_qsv) ---"
    test_transcode "hevc_qsv" "qsv_h265" "Intel Quick Sync H.265"

elif [ "$GPU_TYPE" = "vaapi" ]; then
    echo "--- Test 2: VAAPI H.264 (h264_vaapi) ---"
    if check_vaapi_encoders "VAProfileH264Main"; then
        output_file="$OUTPUT_DIR/${INPUT_FILE%.mp4}_vaapi_h264.mp4"
        LIBVA_DRIVER_NAME=iHD ffmpeg -hide_banner -y -vaapi_device "$VAAPI_DEVICE" -i "$INPUT_FILE" -t 10 -vf 'format=nv12,hwupload' -c:v h264_vaapi -c:a copy "$output_file" 2>&1 | tail -5
        if [ -f "$output_file" ]; then
            size=$(du -h "$output_file" | cut -f1)
            echo "Output: $output_file ($size)"
            echo "Status: SUCCESS"
        else
            echo "Status: FAILED"
        fi
    else
        echo "Status: SKIPPED (Hardware does not support H.264 encoding)"
    fi
    
    echo "--- Test 3: VAAPI H.265 (hevc_vaapi) ---"
    if check_vaapi_encoders "VAProfileHEVCMain"; then
        output_file="$OUTPUT_DIR/${INPUT_FILE%.mp4}_vaapi_h265.mp4"
        LIBVA_DRIVER_NAME=iHD ffmpeg -hide_banner -y -vaapi_device "$VAAPI_DEVICE" -i "$INPUT_FILE" -t 10 -vf 'format=nv12,hwupload' -c:v hevc_vaapi -c:a copy "$output_file" 2>&1 | tail -5
        if [ -f "$output_file" ]; then
            size=$(du -h "$output_file" | cut -f1)
            echo "Output: $output_file ($size)"
            echo "Status: SUCCESS"
        else
            echo "Status: FAILED"
        fi
    else
        echo "Status: SKIPPED (Hardware does not support HEVC encoding)"
        echo "Note: Intel Skylake (Gen9) GPU does not support HEVC hardware encoding."
        echo "      HEVC encoding requires Kaby Lake (Gen9.5) or newer."
    fi
fi

echo "--- Test 5: Quick hardware check with ffprobe ---"
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,width,height -of csv=p=0 "$INPUT_FILE"
echo ""

echo "========== Transcode Test Complete =========="
echo "Output files in: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"
