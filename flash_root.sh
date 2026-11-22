#!/bin/bash
set -e

cd /home/niro/Projects/realme-experiments/mtkclient
source .venv/bin/activate

echo "=========================================================="
echo "    REALME 8 4G (RMX3085) - FLASH MAGISK ROOT & PATCHED LK"
echo "=========================================================="
echo ""
echo "Target files:"
echo " - Boot Partition: /home/niro/Projects/realme-experiments/magisk_patched_a19_boot.img"
echo " - LK/LK2 Partitions: /home/niro/Projects/realme-experiments/lk_patched.img"
echo ""
echo "Instructions:"
echo " 1. Ensure the phone is completely POWERED OFF."
echo " 2. Press and hold VOLUME UP (+) and VOLUME DOWN (-) together."
echo " 3. Connect the USB cable to PC while holding both buttons."
echo " 4. Keep holding until the flash completes and the device resets."
echo ""
echo "----------------------------------------------------------"
echo "Listening for device in BROM mode..."
echo "----------------------------------------------------------"
echo ""

if ! python mtk.py multi "w boot ../magisk_patched_a19_boot.img;w lk,lk2 ../lk_patched.img;reset"; then
    echo ""
    echo "Multi-command fallback: running individual commands..."
    python mtk.py w boot ../magisk_patched_a19_boot.img
    python mtk.py w lk,lk2 ../lk_patched.img
    python mtk.py reset
fi

echo ""
echo "=========================================================="
echo " Magisk Root & Patched LK flashed successfully!           "
echo " Phone is resetting into Android...                       "
echo "=========================================================="
echo ""
echo "Press Enter to close this terminal..."
read -r
