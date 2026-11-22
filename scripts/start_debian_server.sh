#!/system/bin/sh
# ==============================================================================
# Realme 8 4G: Clean Debian 12 + Docker Server Bootstrapper
# ==============================================================================
DIR="/data/debian"

echo "=== [1/6] Stopping old services ==="
pkill -x sshd 2>/dev/null || true
pkill -x dockerd 2>/dev/null || true
pkill -x containerd 2>/dev/null || true

echo "=== [2/6] Cleaning up old mounts ==="
umount -l $DIR/var/lib/docker 2>/dev/null || true
for sub in sys/fs/cgroup/* sys/fs/cgroup dev/pts dev/shm dev proc sys; do
    umount -l $DIR/$sub 2>/dev/null || true
done
while umount $DIR 2>/dev/null; do :; done

echo "=== [3/6] Setting up root mountpoint ==="
mkdir -p $DIR
mount -o bind $DIR $DIR
mount --make-rshared $DIR

echo "=== [4/6] Mounting filesystems & cgroups ==="
mkdir -p $DIR/proc $DIR/sys $DIR/dev $DIR/dev/pts $DIR/dev/shm $DIR/tmp $DIR/run/sshd $DIR/var/lib/docker
mount -t proc proc $DIR/proc
mount -t sysfs sys $DIR/sys
mount -o bind /dev $DIR/dev
mount -t devpts devpts $DIR/dev/pts
mount -t tmpfs tmpfs $DIR/dev/shm
chmod 1777 $DIR/tmp $DIR/dev/shm

mount -t tmpfs -o mode=755 cgroup $DIR/sys/fs/cgroup
for cg in cpuset cpu cpuacct schedtune blkio memory devices freezer pids; do
    mkdir -p $DIR/sys/fs/cgroup/$cg
    mount -t cgroup -o $cg cgroup $DIR/sys/fs/cgroup/$cg 2>/dev/null || true
done

echo "=== [5/6] Mounting ext4 Docker storage ==="
if [ ! -f /data/docker.img ]; then
    truncate -s 15G /data/docker.img
    mkfs.ext4 -F /data/docker.img
fi
LOOP=$(losetup -j /data/docker.img | cut -d: -f1 | head -n1)
if [ -z "$LOOP" ]; then
    LOOP=$(losetup -f)
    losetup $LOOP /data/docker.img
fi
mount -t ext4 -o noatime $LOOP $DIR/var/lib/docker

# Kernel & Network parameters
sysctl -w net.ipv4.ip_unprivileged_port_start=0 >/dev/null
sysctl -w net.ipv4.ip_forward=1 >/dev/null
setenforce 0 2>/dev/null || true

# Wi-Fi CAM (low latency) & iptables
echo 1 > /proc/net/wlan/setCAM 2>/dev/null || true
echo "ForceEnable:1" > /proc/net/wlan/autoPerfCfg 2>/dev/null || true
iptables -I INPUT 1 -p tcp -m multiport --dports 22,80,443,6379,8080,3000,9000,5000 -j ACCEPT 2>/dev/null || iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT 2>/dev/null || true
iptables -I INPUT 1 -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || true

echo "nameserver 1.1.1.1" > $DIR/etc/resolv.conf
echo "nameserver 8.8.8.8" >> $DIR/etc/resolv.conf

# Ensure Docker daemon configuration
mkdir -p $DIR/etc/docker
cat << 'EOF' > $DIR/etc/docker/daemon.json
{
  "storage-driver": "vfs",
  "iptables": false
}
EOF

echo "=== [6/6] Launching OpenSSH & Docker Daemon ==="
chroot $DIR /bin/bash -c "
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
mount --make-rprivate / 2>/dev/null || true
mkdir -p /run/sshd /var/run/sshd
/usr/sbin/sshd 2>/dev/null || true
sleep 1
export DOCKER_RAMDISK=true
nohup dockerd > /tmp/dockerd.log 2>&1 < /dev/null &
"

echo "=== Debian Server Online! ==="
