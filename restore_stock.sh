#!/bin/bash
set -e

cd /home/niro/Projects/realme-experiments/mtkclient
source .venv/bin/activate

echo "=========================================================="
echo "    REALME 8 4G (RMX3085) - RESTORE STOCK A.19 FIRMWARE   "
echo "=========================================================="
echo ""
echo "Target files (clean paths):"
echo " - Boot:   /home/niro/Projects/realme-experiments/stock_a19_boot.img"
echo " - VBMeta: /home/niro/Projects/realme-experiments/stock_a19_vbmeta.img"
echo ""
echo "Instructions:"
echo " 1. Press and hold ALL THREE buttons:"
echo "    VOLUME UP (+) + VOLUME DOWN (-) + POWER BUTTON"
echo "    until the screen turns black and vibration stops."
echo " 2. As soon as the screen goes black, release the Power button,"
echo "    but KEEP HOLDING Volume Up and Volume Down together!"
echo " 3. MTKClient will detect BROM and restore stock boot & vbmeta."
echo ""
echo "----------------------------------------------------------"
echo "Listening for device in BROM mode..."
echo "----------------------------------------------------------"
echo ""

python mtk.py multi "w boot ../stock_a19_boot.img;w vbmeta ../stock_a19_vbmeta.img;reset"

echo ""
echo "=========================================================="
echo " Stock A.19 boot and vbmeta restored successfully!        "
echo " Your phone is now booting cleanly into Android 11.       "
echo "=========================================================="
echo ""
echo "Press Enter to exit..."
read -r
