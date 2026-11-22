#!/bin/bash
set -e

SERIAL="${1:-${DEVICE_SERIAL:-device}}"
TARGET_DIR="/data/debian"
ROOTFS_URL="https://blr1mirror01.do.images.linuxcontainers.org/images/debian/bookworm/arm64/default/20261118_05:24/rootfs.tar.xz"
TMP_ARCHIVE="/data/local/tmp/debian-rootfs.tar.xz"

echo "=== Bootstrapping Debian 12 Chroot on Realme 8 ($SERIAL) ==="

echo "[*] Cleaning old temporary files and preparing $TARGET_DIR..."
adb -s "$SERIAL" shell "su -c 'rm -f $TMP_ARCHIVE; mkdir -p $TARGET_DIR /data/local/tmp'"

echo "[*] Downloading official Debian 12 (arm64) rootfs (95MB)..."
adb -s "$SERIAL" shell "su -c '
curl -L -o $TMP_ARCHIVE \"$ROOTFS_URL\"
ls -lh $TMP_ARCHIVE
'"

echo "[*] Extracting rootfs into $TARGET_DIR (UFS 2.1 F2FS storage)..."
adb -s "$SERIAL" shell "su -c '
cd $TARGET_DIR
tar -xf $TMP_ARCHIVE
echo \"nameserver 1.1.1.1\" > etc/resolv.conf
echo \"nameserver 8.8.8.8\" >> etc/resolv.conf
echo \"realme8-server\" > etc/hostname
echo \"127.0.0.1 localhost realme8-server\" > etc/hosts
'"

echo "[*] Initializing mounts and configuring OpenSSH & base server packages..."
adb -s "$SERIAL" shell "su -c '
mount -t proc proc $TARGET_DIR/proc 2>/dev/null || true
mount -t sysfs sys $TARGET_DIR/sys 2>/dev/null || true
mount -o bind /dev $TARGET_DIR/dev 2>/dev/null || true
mount -t devpts devpts $TARGET_DIR/dev/pts 2>/dev/null || true
mount -t tmpfs tmpfs $TARGET_DIR/dev/shm 2>/dev/null || true

chroot $TARGET_DIR /bin/bash -c \"
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
apt update
DEBIAN_FRONTEND=noninteractive apt install -y openssh-server sudo curl wget htop git iptables ca-certificates
mkdir -p /run/sshd /var/run/sshd
sed -i \\\"s/#PermitRootLogin prohibit-password/PermitRootLogin yes/\\\" /etc/ssh/sshd_config 2>/dev/null || true
echo \\\"root:realme8\\\" | chpasswd
\"
'"

echo "=== Debian 12 Base Setup Complete! ==="
