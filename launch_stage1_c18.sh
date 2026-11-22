#!/usr/bin/env bash
set -e

DIR="/home/niro/Projects/realme-experiments"
cd "$DIR"

clear
echo "=================================================================="
echo "    REALME 8 4G (RMX3085) — STAGE 1: UPGRADE TO REALME UI 3.0    "
echo "=================================================================="
echo ""
echo " Firmware Base: Realme UI 3.0 (C.18 Stock)"
echo " Scatter File:  $DIR/RMX3085_C.18_IN_FW_by_SG/MT6785_Android_scatter.txt"
echo " SP Flash Tool: $DIR/SP_Flash_Tool_v5.2044_Linux"
echo ""
echo "------------------------------------------------------------------"
echo " CRITICAL SAFETY CHECKLIST FOR SP FLASH TOOL:"
echo "------------------------------------------------------------------"
echo "  1. Download Mode:       [Download Only] (NEVER Format All + Download!)"
echo "  2. Uncheck Partitions:  [opporeserve2]   (protects NVRAM calibration)"
echo "                          [cdt_engineering] (protects warranty/keys)"
echo "  3. Connection Settings: UART -> /dev/ttyACM0 -> 921600 baud rate"
echo "------------------------------------------------------------------"
echo ""

# Check if device is currently on ADB
if adb devices | grep -q "8PLNBUD6FUEAPRHY.*device"; then
    echo "Device detected via ADB (8PLNBUD6FUEAPRHY)."
    echo ""
    read -p "Would you like to power off the phone automatically now? (y/n): " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        echo "Powering off device..."
        adb -s 8PLNBUD6FUEAPRHY shell "reboot -p" || true
        echo "Device is powering down. Wait 5 seconds until the screen is fully black."
        sleep 5
    fi
fi

echo ""
echo "=================================================================="
echo " STEP 1: BROM PAYLOAD HANDSHAKE"
echo "=================================================================="
echo " Instructions:"
echo "  1. Make sure the phone is completely POWERED OFF and unplugged."
echo "  2. Press and hold BOTH [VOLUME UP] and [VOLUME DOWN] buttons."
echo "  3. While holding both buttons, connect the USB cable to PC."
echo "  4. Release the buttons when MTKClient displays 'Payload sent'."
echo "=================================================================="
echo ""

cd "$DIR/mtkclient"
source .venv/bin/activate

echo "Starting MTKClient payload listener..."
python mtk.py payload

# Attach cdc_acm driver for /dev/ttyACM0
python -c "import usb.core; d = usb.core.find(idVendor=0x0e8d, idProduct=0x0003); d and d.attach_kernel_driver(0)" 2>/dev/null || true

echo ""
echo "=================================================================="
echo " [OK] Payload injected successfully! /dev/ttyACM0 is active."
echo "=================================================================="
echo ""
echo "Launching SP Flash Tool now..."
sleep 1

cd "$DIR/SP_Flash_Tool_v5.2044_Linux"
./flash_tool.sh &
SP_PID=$!

echo ""
echo "------------------------------------------------------------------"
echo " IN SP FLASH TOOL UI:"
echo "------------------------------------------------------------------"
echo "  1. Options -> Option -> Connection -> UART -> /dev/ttyACM0 (921600)"
echo "  2. Click 'choose' next to Scatter-loading File and select:"
echo "     $DIR/RMX3085_C.18_IN_FW_by_SG/MT6785_Android_scatter.txt"
echo "  3. Ensure dropdown is on 'Download Only'."
echo "  4. UNCHECK 'opporeserve2' and 'cdt_engineering' in the partition list."
echo "  5. Click the green 'Download' arrow button at the top."
echo "------------------------------------------------------------------"
echo ""
echo "Flashing takes ~10-15 minutes. Waiting for SP Flash Tool to finish..."
wait $SP_PID 2>/dev/null || true

echo ""
echo "=================================================================="
echo " STEP 2: FORMAT DATA IN STOCK RECOVERY"
echo "=================================================================="
echo "  1. Unplug the USB cable from the phone."
echo "  2. Hold [POWER] + [VOLUME DOWN] until the Realme logo appears."
echo "  3. In Stock Recovery, select: English -> Wipe data -> Format data."
echo "  4. Enter the 4-digit code shown on screen and confirm Format."
echo "  5. Once formatted, tap OK. The phone will reboot into C.18."
echo "=================================================================="
echo ""
echo "Stage 1 Complete! Press Enter to exit..."
read -r
