#!/bin/bash
set -e

SERIAL="${1:-${DEVICE_SERIAL:-device}}"
BACKUP="/home/niro/Projects/realme-experiments/live_working_boot_backup.img"

echo "=== Restoring Known Working Boot Image (Emergency Rollback) ==="

if [ ! -f "$BACKUP" ]; then
    echo "Error: Backup file $BACKUP not found!"
    exit 1
fi

echo "[*] Flashing known-working backup boot image..."
fastboot -s "$SERIAL" flash boot "$BACKUP"

echo "[*] Rebooting into Android..."
fastboot -s "$SERIAL" reboot

echo "=== System restored successfully! ==="
