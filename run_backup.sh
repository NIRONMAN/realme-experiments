#!/bin/bash
set -e

cd /home/niro/Projects/realme-experiments/mtkclient
source .venv/bin/activate

echo "=========================================================="
echo "    REALME 8 4G (RMX3085) - FIRMWARE PARTITION BACKUP    "
echo "=========================================================="
echo ""
echo "Instructions:"
echo " 1. Make sure phone is completely POWERED OFF."
echo " 2. Hold VOLUME UP (+) and VOLUME DOWN (-) together."
echo " 3. Plug in the USB cable to PC while holding both buttons."
echo " 4. Keep holding until MTKClient detects the device."
echo " 5. Once dumping starts, release the volume buttons."
echo ""
echo "----------------------------------------------------------"
echo "Listening for device in BROM mode..."
echo "----------------------------------------------------------"
echo ""

python mtk.py rl --skip userdata,super ../firmware-backup

echo ""
echo "=========================================================="
echo "  Backup completed! Check ../firmware-backup directory.  "
echo "=========================================================="
echo "Press Enter to exit..."
read -r
