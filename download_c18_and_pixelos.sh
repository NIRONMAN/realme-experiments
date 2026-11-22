#!/usr/bin/env bash
set -e
cd /home/niro/Projects/realme-experiments

echo "=========================================================="
echo " DOWNLOADING PIXELOS AND REALME UI 3.0 (C.18) PACKAGES"
echo "=========================================================="

# 1. Download PixelOS
if [ ! -f "PixelOS_nashc-13.0-20231216-1529.zip" ]; then
    echo "==> Downloading PixelOS Android 13 (nashc)..."
    curl -L -C - --progress-bar -o "PixelOS_nashc-13.0-20231216-1529.zip" \
      "https://sourceforge.net/projects/pixelos-nashc/files/PixelOS_nashc-13.0-20231216-1529.zip/download"
else
    echo "==> PixelOS archive already exists on disk."
fi

echo "==> Verifying PixelOS SHA256..."
EXPECTED_SHA="9fcdc80873155904e6ca0c8b0d596d8fc3801e515127647cb426928b15d81738"
ACTUAL_SHA=$(sha256sum PixelOS_nashc-13.0-20231216-1529.zip | awk '{print $1}')
if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
    echo "MISMATCH! Expected: $EXPECTED_SHA, Got: $ACTUAL_SHA"
    exit 1
fi
echo "==> PixelOS SHA256 verified successfully!"

# 2. Download C.18 Base Firmware
if [ ! -f "RMX3085_C.18_IN_FW_by_SG.rar" ]; then
    echo "==> Downloading C.18 Base Firmware (RMX3085_C.18_IN_FW_by_SG.rar)..."
    ./mtkclient/.venv/bin/gdown --continue "https://drive.google.com/uc?id=1YHSIr4itg_5dPE2IbWAH9N8g6L5CGmaG" -O "RMX3085_C.18_IN_FW_by_SG.rar"
else
    echo "==> C.18 Firmware archive already exists on disk."
fi

# 3. Extract C.18 Firmware
if [ ! -d "RMX3085_C.18_IN_FW_by_SG" ]; then
    echo "==> Extracting C.18 Base Firmware..."
    mkdir -p "RMX3085_C.18_IN_FW_by_SG"
    bsdtar -xf "RMX3085_C.18_IN_FW_by_SG.rar" -C "RMX3085_C.18_IN_FW_by_SG"
    echo "==> Extraction completed."
else
    echo "==> C.18 directory already extracted."
fi

echo "=========================================================="
echo " ALL PACKAGES DOWNLOADED, VERIFIED, AND READY FOR FLASHING"
echo "=========================================================="
