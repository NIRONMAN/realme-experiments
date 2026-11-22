#!/usr/bin/env bash
set -e

DIR="/home/niro/Projects/realme-experiments"
cd "$DIR"

echo "=================================================================="
echo "   REALME 8 4G (RMX3085) — STAGE 3: FLASH TWRP & DISABLE AVB      "
echo "=================================================================="
echo ""

# Reboot to bootloader if on ADB
if adb devices | grep -q "${DEVICE_SERIAL:-device}.*device"; then
    echo "[*] Rebooting device into Fastboot mode..."
    adb -s ${DEVICE_SERIAL:-device} reboot bootloader
fi

echo "[*] Waiting for device in Fastboot mode..."
count=0
while ! fastboot devices | grep -q "${DEVICE_SERIAL:-device}"; do
    sleep 1
    count=$((count + 1))
    if [ "$count" -ge 30 ]; then
        echo "[!] Timeout waiting for Fastboot. Current devices:"
        fastboot devices || true
        adb devices || true
        exit 1
    fi
done

echo "[+] Device detected in Fastboot mode!"
echo ""

echo "[*] Flashing vbmeta (disabling AVB and dm-verity)..."
fastboot --disable-verity --disable-verification flash vbmeta "$DIR/vbmeta_disabled.img"

echo "[*] Flashing TWRP Recovery..."
fastboot flash recovery "$DIR/twrp_rmx3085_20240405.img"

echo ""
echo "=================================================================="
echo " [SUCCESS] TWRP Recovery & Disabled vbmeta Flashed!"
echo " Rebooting into TWRP Recovery now..."
echo "=================================================================="
fastboot reboot recovery || echo "[NOTE] Please hold Power + Volume Down if automatic reboot to recovery is not supported."
