#!/bin/bash
set -e

cd /home/niro/Projects/realme-experiments/mtkclient
source .venv/bin/activate

echo "=========================================================="
echo "   REALME 8 4G (RMX3085) - FLASH MAGISK ROOT BOOT IMAGE   "
echo "=========================================================="
echo ""
echo "Target file:"
echo " - Boot Partition: /home/niro/Projects/realme-experiments/magisk_patched_boot.img"
echo ""
echo "Instructions:"
echo " 1. Ensure the phone is completely POWERED OFF."
echo " 2. Press and hold VOLUME UP (+) and VOLUME DOWN (-) together."
echo " 3. Connect the USB cable to PC while holding both buttons."
echo " 4. Keep holding until MTKClient detects BROM and finishes flashing."
echo ""
echo "----------------------------------------------------------"
echo "Listening for device in BROM mode..."
echo "----------------------------------------------------------"
echo ""

if ! python mtk.py multi "w boot ../magisk_patched_boot.img;reset"; then
    echo ""
    echo "Multi-command fallback: running individual commands..."
    python mtk.py w boot ../magisk_patched_boot.img
    python mtk.py reset
fi

echo ""
echo "=========================================================="
echo " Magisk Patched Boot flashed successfully!                "
echo " Your Realme 8 is now rebooting with root access!         "
echo "=========================================================="
echo ""
echo "Press Enter to exit..."
read -r
