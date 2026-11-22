#!/bin/bash
set -e

SERIAL="${1:-${DEVICE_SERIAL:-device}}"
IMAGE="/home/niro/Projects/realme-experiments/boot_docker_nashc.img"

echo "=== Flashing Docker-Enabled Boot Image to Realme 8 ($SERIAL) ==="

if [ ! -f "$IMAGE" ]; then
    echo "Error: $IMAGE not found!"
    exit 1
fi

if adb -s "$SERIAL" get-state >/dev/null 2>&1; then
    echo "[*] Device detected via ADB. Rebooting to bootloader (Fastboot)..."
    adb -s "$SERIAL" reboot bootloader
    sleep 4
fi

echo "[*] Flashing new Docker-enabled boot.img..."
fastboot -s "$SERIAL" flash boot "$IMAGE"

echo "[*] Rebooting device into PixelOS Android 13..."
fastboot -s "$SERIAL" reboot

echo ""
echo "=== Done! Phone is booting with the Docker kernel. ==="
