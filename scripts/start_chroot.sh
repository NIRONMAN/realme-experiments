#!/bin/bash
# ==============================================================================
# Realme 8 4G: Linux Chroot Launcher & Service Starter
# ==============================================================================

SERIAL="${1:-8PLNBUD6FUEAPRHY}"
DIR="/data/debian"

echo "=== Starting Linux Server on Realme 8 ($SERIAL) ==="

adb -s "$SERIAL" shell "su -c '
DIR=\"/data/debian\"

# 1. Unshare or ensure shared namespace
mount --make-rshared / 2>/dev/null || true

# 2. Mount virtual filesystems
mountpoint -q \$DIR/proc || mount -t proc proc \$DIR/proc
mountpoint -q \$DIR/sys || mount -t sysfs sys \$DIR/sys
mountpoint -q \$DIR/dev || mount -o bind /dev \$DIR/dev
mountpoint -q \$DIR/dev/pts || mount -t devpts devpts \$DIR/dev/pts
mountpoint -q \$DIR/dev/shm || mount -t tmpfs tmpfs \$DIR/dev/shm

# 3. Allow binding to ports < 1024 (e.g. 80, 443, 22)
sysctl -w net.ipv4.ip_unprivileged_port_start=0 >/dev/null
sysctl -w net.ipv4.ip_forward=1 >/dev/null

# 4. Update DNS
echo \"nameserver 1.1.1.1\" > \$DIR/etc/resolv.conf
echo \"nameserver 8.8.8.8\" >> \$DIR/etc/resolv.conf

# 5. Start SSH Server and Daemons inside chroot
echo \"[*] Launching SSH and services inside chroot...\"
chroot \$DIR /bin/bash -c \"
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
mkdir -p /run/sshd /var/run/sshd
service ssh restart
service nginx start 2>/dev/null || true
service redis-server start 2>/dev/null || true
service postgresql start 2>/dev/null || true
\"

# Report network IP
echo \"=== Server Network Interfaces ===\"
ip addr show wlan0 2>/dev/null | grep \"inet \" || ip addr show eth0 2>/dev/null | grep \"inet \"
'"

echo "=== Linux Server Running! ==="
echo "Connect via SSH: ssh root@<phone-ip> (Password: realme8)"
