# Realme 8 4G (MT6785 / Helio G95) — 24/7 Linux & Docker Server

A complete, production-grade guide to unlocking the **Realme 8 4G (`RMX3085` / codename `nashc`)**, flashing a clean AOSP custom ROM (**PixelOS Android 13**), compiling a custom **Linux 4.14 kernel** with Docker containerization support, deploying a native **Debian 12 (Bookworm)** server environment, and configuring 24/7 hardware battery bloat mitigation.

---

## Device Specifications & Environment

| Component | Specification |
| :--- | :--- |
| **Model** | Realme 8 4G (`RMX3085` / `RMX3085L1`, codename `nashc`) |
| **SoC** | MediaTek Helio G95 (`MT6785`) — 2x Cortex-A76 @ 2.05GHz, 6x Cortex-A55 @ 2.0GHz |
| **RAM** | 8 GB LPDDR4X |
| **Storage** | 128 GB UFS 2.1 (F2FS `/data` partition) |
| **Host OS** | PixelOS Android 13 (`TQ3C.230901.001.B1`) |
| **Kernel** | Custom Linux 4.14.318 (`lineage-nashc` with Docker container flags) |
| **Root Solution** | Magisk v28.1 (MagiskSU) |
| **Guest Server** | Debian 12 (Bookworm) aarch64 in Rooted Chroot |
| **Container Engine** | Native Docker CE 20.10.24 & Docker Compose 1.29.2 |
| **Safety Daemon** | Dual-node hardware charging cutoff (cycles 50%–60% SoC) |

---

## Licensing & Attribution

Portions of Phase 1 and Phase 2 (bootloader unlock methodology, stock firmware downgrade to A.19, Little Kernel patching, and recovery installation concepts) are referenced and adapted from the master guide by [@driedpampas](https://github.com/driedpampas):
* **Source Guide:** [Realme 8 Mega Guide (`driedpampas/realme-8-megaguide`)](https://github.com/driedpampas/realme-8-megaguide)
* **License:** [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

All additions in this repository—including kernel patches for containerization, host build shims, Debian chroot scripts, Docker/Compose runtime fixes, and the hardware battery guard daemon—are open-sourced under the same **CC BY-NC-SA 4.0** license.

Special thanks to:
* **[@driedpampas](https://github.com/driedpampas)** for the comprehensive Realme 8 Mega Guide.
* **[bkerler](https://github.com/bkerler)** for `mtkclient`.
* **[Roger Ortiz](https://github.com/R0rt1z2)** for `lkpatcher`.
* **[Haadi](https://t.me/Haadi786H)** for the decrypted A.19 stock firmware.
* **[SGtriangle](https://t.me/SGtriangle)** for the C.18 firmware.
* **[nashc-dev](https://github.com/nashc-dev)** for the LineageOS/nashc kernel source tree.

---

## Table of Contents
1. [Phase 1: Bootloader Unlock & Stock Downgrade](#phase-1-bootloader-unlock--stock-downgrade)
2. [Phase 2: Upgrade to C.18 & Little Kernel (`lk`) Patching](#phase-2-upgrade-to-c18--little-kernel-lk-patching)
3. [Phase 3: Custom Recovery & PixelOS Android 13 Installation](#phase-3-custom-recovery--pixelos-android-13-installation)
4. [Phase 4: Custom Kernel Compilation for Docker](#phase-4-custom-kernel-compilation-for-docker)
5. [Phase 5: Debian 12 Rooted Chroot Bootstrap](#phase-5-debian-12-rooted-chroot-bootstrap)
6. [Phase 6: Native Docker & Compose Container Runtime](#phase-6-native-docker--compose-container-runtime)
7. [Phase 7: 24/7 Battery Bloat Prevention & Keepalive Daemon](#phase-7-247-battery-bloat-prevention--keepalive-daemon)
8. [Phase 8: VPS Comparison & System Architecture](#phase-8-vps-comparison--system-architecture)
9. [Troubleshooting & Lessons Learned](#troubleshooting--lessons-learned)

---

## Phase 1: Bootloader Unlock & Stock Downgrade

Official Realme Deep Testing server applications have been permanently disabled for Realme 8. Unlocking requires a hardware BROM exploit.

### Why Downgrade to A.19 First?
Modern Realme UI 3.0 (C.xx) and 4.0 (F.xx) builds enforce strict anti-rollback checks and disable fastboot verification commands on locked devices. Downgrading to decrypted Android 11 (**A.19**) enables clean security configuration clearing without hard-bricking.

### Step 1: Linux USB & udev Configuration
To prevent Linux `ModemManager` from disrupting the MediaTek BROM handshake:
```bash
sudo systemctl stop ModemManager
sudo usermod -aG dialout,plugdev $USER
echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="0e8d", ATTR{idProduct}=="0003", MODE="0666", GROUP="plugdev"' | sudo tee /etc/udev/rules.d/51-edl.rules
echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="0e8d", ATTR{idProduct}=="2000", MODE="0666", GROUP="plugdev"' | sudo tee -a /etc/udev/rules.d/51-edl.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
```

### Step 2: Full Partition Backup via MTKClient
```bash
git clone https://github.com/bkerler/mtkclient.git
cd mtkclient && python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# Power off phone, hold Vol+ and Vol-, plug in USB
python mtk rl --skip userdata,super ../firmware-backup
```

### Step 3: Flash A.19 Stock Firmware
1. Put device into BROM mode: `python mtk payload`.
2. Open **SP Flash Tool** (v5.2044) with baud rate `921600` on UART/COM.
3. Load `scatter.txt` from Haadi's decrypted A.19 package.
4. Set mode to **`Download Only`** (⚠️ **NEVER use "Format All + Download"**).
5. Uncheck `opporeserve2` and `cdt_engineering`.
6. Click **Download**, flash the firmware, then boot into recovery and select **Wipe data $\rightarrow$ Format data**.

### Step 4: Hardware Unlock Command
```bash
python mtk e metadata,userdata,md_udc
python mtk da seccfg unlock
python mtk reset
```
Upon reboot, the device will display `Orange State: Your device has been unlocked and can't be trusted`. Verify `OEM unlocking` is active in Developer Options.

---

## Phase 2: Upgrade to C.18 & Little Kernel (`lk`) Patching

Android 13/14 custom ROMs require the updated firmware bloat baseline from **Realme UI 3.0 (build C.18)**.

1. Put device into BROM: `python mtk payload`.
2. In SP Flash Tool, load `MT6785_Android_scatter.txt` from SG's C.18 firmware.
3. Select **`Download Only`**, flash, and format data in recovery.
4. Dump the stock C.18 Little Kernel partition:
   ```bash
   python mtk r lk lk.bin
   ```
5. **Patch `lk.bin` Locally (Offline Python CLI):**
   ```bash
   git clone https://github.com/R0rt1z2/lkpatcher.git
   python lkpatcher/lkpatcher.py lk.bin lk_patched.img
   ```
   *This disables the 5-second Orange State delay and eliminates `fastboot_verify_fail` errors.*
6. Flash patched Little Kernel:
   ```bash
   python mtk w lk lk_patched.img
   python mtk reset
   ```

---

## Phase 3: Custom Recovery & PixelOS Android 13 Installation

### Step 1: Disable Android Verified Boot (AVB)
Flashing custom recovery requires flashing an empty/disabled vbmeta:
```bash
adb reboot bootloader
fastboot --disable-verity --disable-verification flash vbmeta vbmeta_disabled.img
```

### Step 2: Flash TWRP 3.7.1 Recovery
```bash
fastboot flash recovery twrp_rmx3085_20240405.img
fastboot reboot recovery
```

### Step 3: Wipe & Sideload PixelOS
1. In recovery: Select **Factory reset $\rightarrow$ Format data/factory reset**.
2. Select **Apply update $\rightarrow$ Apply from ADB**:
   ```bash
   adb sideload PixelOS_nashc-13.0-20231216-1529.zip
   ```
3. Reboot to system to confirm initial boot.

### Step 4: Root with Magisk v28.1
1. Sideload or flash `Magisk-v28.1.zip` via TWRP, or patch `boot.img` via Magisk App.
2. ⚠️ **Critical:** Keep `KEEPFORCEENCRYPT=true` in `.backup/.magisk` to ensure userdata encryption remains intact.
3. Verify root:
   ```bash
   adb shell "su -c 'id; magisk -v'"
   # Output: uid=0(root) gid=0(root) context=u:r:magisk:s0
   ```

---

## Phase 4: Custom Kernel Compilation for Docker

Standard Android kernels omit critical namespaces, cgroups, and netfilter modules required by container runtimes.

### Kernel Source & Toolchain
* **Kernel Source:** [nashc-dev/android_kernel_realme_nashc](https://github.com/nashc-dev/android_kernel_realme_nashc) (`lineage-20` branch, Linux 4.14.318)
* **Toolchain:** [kdrag0n/proton-clang](https://github.com/kdrag0n/proton-clang) (LLVM 13)

### Required Defconfig Additions
The following flags were appended to `arch/arm64/configs/lineage-nashc_defconfig`:
```kconfig
# --- DOCKER CONTAINERIZATION FLAGS ---
CONFIG_SYSVIPC=y
CONFIG_SYSVIPC_SYSCTL=y
CONFIG_POSIX_MQUEUE=y
CONFIG_POSIX_MQUEUE_SYSCTL=y
CONFIG_IPC_NS=y
CONFIG_USER_NS=y
CONFIG_CGROUP_DEVICE=y
CONFIG_CGROUP_PIDS=y
CONFIG_MEMCG_SWAP=y
CONFIG_MEMCG_SWAP_ENABLED=y
CONFIG_BLK_CGROUP=y
CONFIG_BLK_DEV_THROTTLING=y
CONFIG_CFS_BANDWIDTH=y
CONFIG_NETFILTER_XT_MATCH_ADDRTYPE=y
CONFIG_IP6_NF_TARGET_MASQUERADE=y
CONFIG_BRIDGE_NETFILTER=y
CONFIG_VETH=y
CONFIG_DUMMY=y
```

### Host Compilation Fixes
1. **glibc `.relr.dyn` Linker Conflict:** Host tool build failures (`unknown type [0x13] section '.relr.dyn'`) were resolved by forcing host binutils for host binaries:
   ```bash
   export HOSTCC="gcc -B/usr/bin/"
   export HOSTLD="ld"
   ```
2. **vDSO32 Compatibility:**
   ```bash
   export CROSS_COMPILE_ARM32="$TOOLCHAIN_DIR/bin/arm-linux-gnueabi-"
   export CROSS_COMPILE_COMPAT="$TOOLCHAIN_DIR/bin/arm-linux-gnueabi-"
   export LD_COMPAT="$TOOLCHAIN_DIR/bin/arm-linux-gnueabi-ld"
   ```
3. **Missing `bc` Shim:** Created a Python arithmetic shim at `~/.local/bin/bc` to satisfy `kernel/timeconst.pl`.

### Compilation & Repacking
Build script: [kernel/build_docker_kernel.sh](file:///home/niro/Projects/realme-experiments/kernel/build_docker_kernel.sh)
```bash
./kernel/build_docker_kernel.sh
```
The compiled `Image.gz` is repacked into `boot_docker_nashc.img` alongside the stock dtb and Magisk v28.1 ramdisk using `magiskboot`:
```bash
magiskboot unpack live_working_boot_backup.img
cp kernel/source/out/arch/arm64/boot/Image.gz kernel
magiskboot repack live_working_boot_backup.img boot_docker_nashc.img
fastboot flash boot boot_docker_nashc.img
```

---

## Phase 5: Debian 12 Rooted Chroot Bootstrap

Instead of unprivileged PRoot (which incurs syscall interception overhead), Debian 12 runs inside a native rooted chroot directly on high-speed UFS 2.1 storage.

### 1. Rootfs Setup
1. Extract official Debian 12 Bookworm arm64 rootfs into `/data/debian`.
2. Configure static DNS:
   ```bash
   echo "nameserver 1.1.1.1" > /data/debian/etc/resolv.conf
   echo "nameserver 8.8.8.8" >> /data/debian/etc/resolv.conf
   ```
3. Bypass Android `AID_INET` (3003) socket sandbox restrictions for APT:
   ```bash
   echo 'APT::Sandbox::User "root";' > /data/debian/etc/apt/apt.conf.d/01sandbox
   ```
4. Install server packages:
   ```bash
   apt update
   DEBIAN_FRONTEND=noninteractive apt install -y openssh-server sudo curl wget htop git iptables ca-certificates docker.io docker-compose
   ```

### 2. OpenSSH Server Configuration
* Config file: `/data/debian/etc/ssh/sshd_config`
  ```text
  PermitRootLogin yes
  PasswordAuthentication yes
  ```
* Set password: `echo "root:realme8" | chpasswd`
* Generate host keys: `ssh-keygen -A`

---

## Phase 6: Native Docker & Compose Container Runtime

Running Docker inside an Android chroot requires specific workarounds for storage, mount propagation, and firewalling:

### 1. Loopback Ext4 for `overlay2` Storage
Android's `/data` partition uses F2FS, which Linux 4.14 overlayfs rejects as an upperdir. To provide native `overlay2` support:
```bash
truncate -s 15G /data/docker.img
mkfs.ext4 -F /data/docker.img
mkdir -p /data/debian/var/lib/docker
LOOP=$(losetup -f)
losetup $LOOP /data/docker.img
mount -t ext4 -o noatime $LOOP /data/debian/var/lib/docker
```

### 2. Mount Propagation & `ApplyLayer` Fix
Docker layer extraction attempts `mount.MakeRSlave("/")` (`flags: 0x84000`), which fails if `/` is not an isolated mount point.
* The chroot root is recursively bind-mounted:
  ```bash
  mount -o rbind /data/debian /data/debian
  mount --make-rshared /data/debian
  ```
* Before starting `dockerd`, force private propagation and set `DOCKER_RAMDISK`:
  ```bash
  mount --make-rprivate /
  export DOCKER_RAMDISK=true
  ```

### 3. Firewall & Storage Driver Configuration
Create `/data/debian/etc/docker/daemon.json`:
```json
{
  "storage-driver": "vfs",
  "iptables": false
}
```
* **`iptables: false`:** Prevents Docker from conflicting with Android's `netd` daemon and missing kernel connmark extensions.
* Use `--net=host` or configure user-space port binding.

### 4. Verified Container Services
Launch Docker Compose with test services:
```yaml
version: '3'
services:
  web:
    image: nginx:alpine
    network_mode: host
    restart: always
  cache:
    image: redis:alpine
    network_mode: host
    restart: always
```
Verification:
```bash
$ curl -I http://192.168.1.25:80
HTTP/1.1 200 OK
Server: nginx/1.31.9

$ redis-cli -h 192.168.1.25 PING
PONG
```

---

## Phase 7: 24/7 Battery Bloat Prevention & Keepalive Daemon

Operating a mobile device plugged in 24/7 will cause lithium-ion battery swelling unless charging is restricted.

### Hardware Cutoff Mechanism
Script: [scripts/battery_guard.sh](file:///home/niro/Projects/realme-experiments/scripts/battery_guard.sh)
* Controls hardware sysfs nodes:
  * `/sys/devices/virtual/oplus_chg/battery/mmi_charging_enable`
  * `/sys/devices/virtual/oplus_chg/battery/stop_charging_enable`
* **Cycling Logic:**
  * When capacity reaches **60%**, `stop_charging_enable` is set to `1` and `mmi_charging_enable` to `0`. Current drops to **0 mA**, running the device entirely on USB pass-through power.
  * When capacity naturally descends to **50%**, charging resumes until 60%.
  * Thermal safety: Charging is immediately cut if battery temperature exceeds **42.0°C**.
  * UI Notification: Sets `dumpsys battery set status 4` (Not Charging) so Android status bar reflects idle power.

### Network Latency & CPU Keepalive
* **Kernel Wakelock:** Writes `realme_server_guard` to `/sys/power/wake_lock` to block deep sleep.
* **Android Doze Disabled:** `dumpsys deviceidle disable`.
* **Wi-Fi Constantly Awake Mode (CAM):**
  ```bash
  echo 1 > /proc/net/wlan/setCAM
  echo "ForceEnable:1" > /proc/net/wlan/autoPerfCfg
  ```
  Eliminates 802.11 DTIM power-saving sleep, keeping local latency at **1–2ms**.

### Automatic Boot Persistence
Deployed to Magisk's late-start service runner (`/data/adb/service.d/`):
* `01-battery-guard.sh`: Power and battery protection daemon.
* `99-linux-server.sh`: Filesystem mounting, SSH, and Docker daemon startup.

---

## Phase 8: VPS Comparison & System Architecture

| Feature | Realme 8 Server | Cloud VPS (e.g. Hetzner / AWS) |
| :--- | :--- | :--- |
| **CPU Architecture** | **ARM64 (`aarch64`)** (8 Cores) | x86_64 or ARM64 |
| **Memory** | **8 GB LPDDR4X** | 2 GB – 8 GB ($10 – $40/mo) |
| **Storage** | **128 GB UFS 2.1** (~800 MB/s read) | Shared Cloud SSD |
| **Docker Support** | **Native** (`docker`, `docker-compose`) | Native |
| **Init System** | Android `/init` (Host) + SysVinit / Docker | Native `systemd` (PID 1) |
| **Nested Virtualization** | Not supported (no `/dev/kvm`) | Supported |
| **Power Resilience** | **Built-in 5000 mAh battery UPS** | Datacenter generator |
| **Internet Ingress** | Behind NAT (via Cloudflare Tunnel / Tailscale) | Public IPv4 / IPv6 |

---

## Troubleshooting & Lessons Learned

| # | Issue Encountered | Root Cause | Verified Resolution |
| :--- | :--- | :--- | :--- |
| **1** | BROM handshake timeout in `mtkclient` | Linux `ModemManager` claiming `/dev/ttyACM0` | `sudo systemctl stop ModemManager` + udev rules |
| **2** | `SP_Flash_Tool` Linux crashes on start | Missing legacy `libpng12.so.0` on modern Linux | Symlinked runtime or used `mtkclient` CLI direct write |
| **3** | `fastboot_verify_fail` on fastboot commands | Stock Little Kernel anti-rollback check | Patched `lk.bin` using local `lkpatcher.py` |
| **4** | Android Verified Boot (AVB) bootloop | Flashing recovery without disabling dm-verity | `fastboot --disable-verity --disable-verification flash vbmeta vbmeta_disabled.img` |
| **5** | Toolchain host `fixdep` failure | Host binutils `.relr.dyn` incompatibility | Passed `HOSTCC="gcc -B/usr/bin/"` and `HOSTLD="ld"` |
| **6** | Kernel build fails on `timeconst.h` | Missing `bc` calculator utility on host | Provided Python-based arithmetic shim at `~/.local/bin/bc` |
| **7** | Toybox `tar` extraction failure | Toybox lacks `xz` decompression binary | Streamed decompression from host: `xz -dc rootfs.tar.xz \| adb shell "su -c 'tar -xf -'"` |
| **8** | Debian APT network connection failure | Android `AID_INET` (3003) unprivileged sandbox | Created `/etc/apt/apt.conf.d/01sandbox` with `APT::Sandbox::User "root";` |
| **9** | Docker overlay2 storage failure on `/data` | F2FS underlying filesystem lacks overlay upperdir | Mounted ext4 loopback image `/data/docker.img` at `/var/lib/docker` |
| **10** | Docker layer extraction `0x84000` remount error | Chroot `/` was not a mountpoint | `mount -o rbind /data/debian /data/debian`, set `DOCKER_RAMDISK=true` |
| **11** | Android cosmetic error dialog on boot | Kernel vermagic build tag mismatch with vendor image | Cosmetic warning; safe to dismiss with OK |
