#!/bin/bash
set -e

cd /home/niro/Projects/realme-experiments/mtkclient
source .venv/bin/activate

echo "=========================================================="
echo "      REALME 8 4G (RMX3085) - MTK PAYLOAD INJECTION       "
echo "=========================================================="
echo ""
echo "Instructions:"
echo " 1. Ensure phone is completely POWERED OFF."
echo " 2. Hold VOLUME UP (+) and VOLUME DOWN (-) together."
echo " 3. Plug in the USB cable to PC while holding both buttons."
echo " 4. Keep holding until MTKClient displays 'Payload sent successfully'."
echo " 5. Leave this window open and proceed to SP Flash Tool to flash!"
echo ""
echo "----------------------------------------------------------"
echo "Listening for device in BROM mode..."
echo "----------------------------------------------------------"
echo ""

python mtk.py payload

# Automatically re-attach cdc_acm so /dev/ttyACM0 is immediately ready for SP Flash Tool
python -c "import usb.core; d = usb.core.find(idVendor=0x0e8d, idProduct=0x0003); d and d.attach_kernel_driver(0)" 2>/dev/null || true

echo ""
echo "=========================================================="
echo " Payload active! Phone is ready for SP Flash Tool.        "
echo "=========================================================="
echo "Keep this window open. Press Enter when flashing is done..."
read -r
