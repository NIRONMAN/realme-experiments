#!/bin/bash
set -e

cd /home/niro/Projects/realme-experiments/mtkclient
source .venv/bin/activate

echo "=========================================================="
echo "    REALME 8 4G (RMX3085) - RESTORE STOCK A.19 BOOT       "
echo "=========================================================="
echo ""
echo "Flashing stock A.19 boot.img to immediately stop the bootloop..."
echo ""
echo "Instructions to catch BROM while phone is rebooting:"
echo " 1. Keep the USB cable connected to PC."
echo " 2. Press and hold ALL THREE buttons together:"
echo "    VOLUME UP (+) + VOLUME DOWN (-) + POWER BUTTON"
echo " 3. As soon as the screen goes black, release the Power button,"
echo "    but KEEP HOLDING Volume Up and Volume Down!"
echo " 4. MTKClient will catch BROM and flash the stock boot.img in ~3 seconds."
echo ""
echo "----------------------------------------------------------"
echo "Listening for device in BROM mode..."
echo "----------------------------------------------------------"
echo ""

python mtk.py multi "w boot '../(A.19)REALME_8_4G_STOCK_ROM_DECRYPTED_GLOBAL_BY_HAADI/boot.img';reset"

echo ""
echo "=========================================================="
echo " Stock boot.img restored successfully!                    "
echo " Your phone is now booting cleanly into Android 11.       "
echo "=========================================================="
echo ""
echo "Press Enter to exit..."
read -r
