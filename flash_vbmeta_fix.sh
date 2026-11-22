#!/bin/bash
set -e

cd /home/niro/Projects/realme-experiments/mtkclient
source .venv/bin/activate

echo "=========================================================="
echo "   REALME 8 4G (RMX3085) - FLASH DISABLED VBMETA (ROOT FIX)"
echo "=========================================================="
echo ""
echo "Writing disabled vbmeta (flags: 0x3) to allow Magisk boot..."
echo ""
echo "Instructions:"
echo " 1. In your phone's recovery screen, select 'English', then tap 'Power off'."
echo " 2. Once the phone is completely off (screen dark):"
echo " 3. Press and hold VOLUME UP (+) and VOLUME DOWN (-) together."
echo " 4. Plug the USB cable in while holding both buttons."
echo " 5. Keep holding until MTKClient flashes vbmeta and resets the phone."
echo ""
echo "----------------------------------------------------------"
echo "Listening for device in BROM mode..."
echo "----------------------------------------------------------"
echo ""

python mtk.py multi "w vbmeta ../vbmeta_disabled.img;reset"

echo ""
echo "=========================================================="
echo " Disabled vbmeta flashed successfully!                    "
echo " Your phone is now booting into Rooted Android 11!        "
echo "=========================================================="
echo ""
echo "Press Enter to exit..."
read -r
