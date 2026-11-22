#!/usr/bin/env bash
set -e

DIR="/home/niro/Projects/realme-experiments"
cd "$DIR"

echo "=================================================================="
echo "   REALME 8 4G (RMX3085) — STAGE 2: FLASH PATCHED LITTLE KERNEL   "
echo "=================================================================="
echo " Patched Image: $DIR/lk_c18_patched.img"
echo " Target:        lk and lk2 partitions"
echo " Purpose:       Unlock Fastboot interface (bypasses fastboot_verify_fail)"
echo "=================================================================="
echo ""

# Power off phone if currently on ADB
if adb devices | grep -q "${DEVICE_SERIAL:-device}.*device"; then
    echo "Phone detected via ADB. Powering down cleanly now..."
    adb -s ${DEVICE_SERIAL:-device} shell "reboot -p" || true
    echo "Phone is shutting down. Please UNPLUG the USB cable from the phone."
    sleep 4
fi

echo ""
echo "------------------------------------------------------------------"
echo " STEPS TO CONNECT IN BROM MODE:"
echo "  1. Make sure USB cable is UNPLUGGED from the phone."
echo "  2. Ensure the screen is completely OFF (black)."
echo "  3. Press and HOLD both [VOLUME UP] and [VOLUME DOWN] buttons."
echo "  4. While holding both buttons, PLUG the USB cable into the phone."
echo "  5. Keep holding until you see 'Device detected' below!"
echo "------------------------------------------------------------------"
echo ""

cd "$DIR/mtkclient"
source .venv/bin/activate

echo "[*] Waiting for BROM connection (Hold Vol+ & Vol- and plug in USB)..."
python mtk.py multi "w lk ../lk_c18_patched.img;w lk2 ../lk_c18_patched.img;reset"

echo ""
echo "=================================================================="
echo " [SUCCESS] Patched Little Kernel written to lk & lk2!"
echo " Fastboot is now fully unlocked!"
echo " Phone will reboot automatically."
echo "=================================================================="
