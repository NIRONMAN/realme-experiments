#!/bin/bash
set -e

cd /home/niro/Projects/realme-experiments/mtkclient
source .venv/bin/activate

echo "=========================================================="
echo "      REALME 8 4G (RMX3085) - BOOTLOADER UNLOCK           "
echo "=========================================================="
echo ""
echo "Instructions:"
echo " 1. Ensure phone is completely POWERED OFF (after formatting data in stock recovery)."
echo " 2. Hold VOLUME UP (+) and VOLUME DOWN (-) together."
echo " 3. Plug in the USB cable to PC while holding both buttons."
echo " 4. Keep holding until MTKClient displays 'Successfully unlocked' / 'Device is reset'."
echo ""
echo "----------------------------------------------------------"
echo "Listening for device in BROM mode..."
echo "----------------------------------------------------------"
echo ""

if ! python mtk.py multi "e metadata,userdata,md_udc;da seccfg unlock;reset"; then
    echo ""
    echo "Multi-command fallback: running individual commands..."
    echo "Please keep holding Vol+ and Vol- or reconnect..."
    python mtk.py e metadata,userdata,md_udc || true
    python mtk.py da seccfg unlock
    python mtk.py reset
fi

echo ""
echo "=========================================================="
echo " Bootloader unlocked successfully!                        "
echo "=========================================================="
echo "Press Enter to exit..."
read -r
