# Realme 8 4G (RMX3085) Bootloader Unlock & Experiments

## Connected Device State
* **Device Model:** Realme 8 4G (`RMX3085` / `RMX3085L1`)
* **Chipset:** MediaTek Helio G95 (`MT6785`)
* **Current Firmware:** `RMX3085_11_C.16` (Android 12 / Realme UI 3.0)
* **Security Patch:** `2023-02-05`
* **Bootloader State:** Locked (`ro.boot.flash.locked = 1`, `verifiedbootstate = green`)
* **ADB Device Serial:** `8PLNBUD6FUEAPRHY`

---

## Why This Method Is Used
* **Realme Deep Testing is dead:** Official server-side application approval for Realme 8 has been disabled by Realme.
* **Hardware BROM Unlock:** The Helio G95 allows direct bootloader security flag unlocking (`seccfg unlock`) via `mtkclient`.
* **Why downgrade to A.19 first:** C.xx (Android 12) and F.xx (Android 13) builds enforce anti-rollback and block Fastboot access on locked devices. Flashing Haadi's decrypted Android 11 (A.19) stock firmware allows clean unlocking without bricking or bootlooping.

---

## Downloads & Resources
1. **Haadi's A.19 Android 11 Decrypted Stock ROM (with Scatter):**
   * Google Drive: [Download A.19 Stock ROM](https://drive.google.com/file/d/1Iy2hwZ0mHQtpHgpyRDRHMZv13FTTvups/view?usp=share_link)
   * Filename: `(A.19)REALME_8_4G_STOCK_ROM_DECRYPTED_GLOBAL_BY_HAADI.zip`
2. **SP Flash Tool Linux:**
   * Repository: [SP_Flash_Tool_v5.2044_Linux.tar.xz](https://github.com/driedpampas/realme-8-megaguide/raw/main/linux/SP_Flash_Tool_v5.2044_Linux.tar.xz)
3. **Reference Master Guide:**
   * GitHub: [driedpampas/realme-8-megaguide](https://github.com/driedpampas/realme-8-megaguide)

---

## Step-by-Step Implementation Workflow

### Step 1: Clone and Set Up MTKClient
```bash
git clone https://github.com/bkerler/mtkclient.git
cd mtkclient
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Step 2: Full Partition Backup (Crucial for IMEI Protection)
```bash
python mtk rl --skip userdata,super ../firmware-backup
```
*Phone powered off $\rightarrow$ Hold **Vol Up + Vol Down** $\rightarrow$ Connect USB cable.*

### Step 3: Flash Android 11 (A.19) via SP Flash Tool
1. In `mtkclient`:
   ```bash
   python mtk payload
   ```
2. Open SP Flash Tool, set UART/COM baud rate to `921600`.
3. Load `scatter.txt` from extracted A.19 firmware.
4. **CRITICAL SETTINGS:**
   * Mode: **`Download Only`** (⚠️ **NEVER "Format All + Download"**)
   * **Uncheck** `opporeserve2` and `cdt_engineering`.
5. Click **Download**, connect phone in BROM mode, and flash.
6. Once completed, enter stock recovery (`Power + Vol Down`), select **Wipe data** $\rightarrow$ **Format data**.

### Step 4: Unlock Bootloader (Completed)
```bash
python mtk e metadata,userdata,md_udc
python mtk da seccfg unlock
python mtk reset
```
*Successfully executed via MTKClient BROM exploit.*

### Step 5: Verify (Completed)
* Device successfully unlocked (`Orange State: Your device has been unlocked and can't be trusted`).
* Verified in Developer Options: OEM unlocking active / Bootloader unlocked.

---

## Phase 2: Rooting (Stock A.19) & Custom Recovery Setup

### 1. Rooting Stock Android 11 (Completed & Verified)
* **Status:** Successfully rooted with **Magisk v28.1** on Stock Android 11 (`RMX3085_11_A.19`).
* **Clean Stock Images Used:**
  - Stock Boot: `stock_a19_boot.img` (32MB / 33,554,432 bytes)
  - Stock VBMeta: `stock_a19_vbmeta.img` (4KB)
* **Key Encryption & AVB Safeguards:**
  - `KEEPFORCEENCRYPT=true` and `KEEPVERITY=true` were verified in the Magisk ramdisk backup configuration (`.backup/.magisk`).
  - Stock Little Kernel (`lk`) and stock `vbmeta` were kept intact, eliminating bootloops and descriptor errors.
* **Flashing Executed via MTKClient:**
  ```bash
  python mtk.py multi "w boot ../magisk_patched_boot.img;reset"
  ```
* **Root Verification Output:**
  ```text
  $ adb shell su -c 'id ; magisk -v'
  uid=0(root) gid=0(root) groups=0(root) context=u:r:magisk:s0
  28.1:MAGISK:R (28100)
  ```

---

### 2. Custom Recovery Architecture & Firmware Requirements
⚠️ **Critical Architectural Note:**
* The device is currently on **Realme UI 2.0 (Android 11, build A.19)**.
* Modern Custom Recoveries (TWRP 3.7.0, OrangeFox, PBRP) and Custom ROMs (Android 13/14: PixelOS, LineageOS 20, crDroid, EvolutionX) are built against **Realme UI 3.0 (Android 12, C.17/C.18)** vendor blobs and partition layout.
* Attempting to flash an Android 13/14 Custom ROM directly on an A.19 base will lead to bootloops or broken modem/Wi-Fi/audio/fingerprint hardware drivers.

---

### 3. Recommended Path to Custom ROMs (Android 13/14)

#### Step A: Upgrade to Realme UI 3 (C.18) Base
1. Open SP Flash Tool (`SP_Flash_Tool_v5.2044_Linux`).
2. Load the C.18 scatter file (`MT6785_Android_scatter.txt`).
3. Set mode to **`Download Only`** (⚠️ **NEVER "Format All + Download"**).
4. **Uncheck** `opporeserve2` and `cdt_engineering` (to preserve device calibration and IMEI).
5. Put phone into BROM mode (`python mtk payload` -> hold Vol+ and Vol- -> connect USB).
6. Flash C.18 firmware.
7. Wipe data / Format data in stock recovery.

#### Step B: Patch `lk` (Little Kernel) for Fastboot Access
On Realme UI 3 (C.18), Fastboot is blocked by default with `fastboot_verify_fail`.
1. In MTKClient:
   ```bash
   python mtk r lk lk.bin
   ```
2. Patch `lk.bin` via `lkpatcher` (or local hex patch script).
3. Flash patched LK:
   ```bash
   python mtk w lk lk-patched.bin
   python mtk reset
   ```

#### Step C: Flash Custom Recovery & Disable AVB
1. Reboot to fastboot:
   ```bash
   adb reboot bootloader
   ```
2. Disable Android Verified Boot verification:
   ```bash
   fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img
   ```
3. Flash custom recovery:
   ```bash
   fastboot flash recovery twrp_rmx3085_20240405.img
   ```
4. Reboot into recovery:
   ```bash
   fastboot reboot recovery
   ```
   *(Or hold **Power + Vol Down** during reboot until recovery splash appears)*

#### Step D: Clean Flash Custom ROM
1. In TWRP / OrangeFox:
   * Navigate to **Wipe** $\rightarrow$ **Format Data** $\rightarrow$ Type `yes`.
2. Navigate to **Advanced** $\rightarrow$ **ADB Sideload**.
3. Flash Custom ROM zip:
   ```bash
   adb sideload <ROM_NAME>.zip
   ```
4. *(If ROM is Vanilla without GApps)*: Sideload GApps package:
   ```bash
   adb sideload MindTheGapps-arm64.zip
   ```
5. *(Optional)* Sideload Magisk for root:
   ```bash
   adb sideload Magisk-v28.1.zip
   ```
6. Tap **Reboot System**. Initial boot takes ~3-5 minutes.

---

## Sourced Custom ROM Options for Realme 8 (nashc / RMX3085)
| ROM | Android Version | GApps | Source / Maintainer | Key Highlights |
| :--- | :--- | :--- | :--- | :--- |
| **PixelOS** | Android 13 | Included | [PixelOS on SourceForge](https://sourceforge.net/projects/pixelos-nashc/) | Official Google Pixel UI, Pixel Launcher, smooth animations, top battery life |
| **crDroid** | Android 14 | Vanilla / GApps | [crDroid on SourceForge](https://sourceforge.net/projects/crdroid-realme-8/) | LineageOS base with extreme customization, Kaeru kernel, active updates |
| **LineageOS 20** | Android 13 | Optional (MTG) | bengris32 (XDA / Telegram) | Pure AOSP stability, lightweight, no telemetry |

