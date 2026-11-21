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

### Step 4: Unlock Bootloader
```bash
python mtk e metadata,userdata,md_udc
python mtk da seccfg unlock
python mtk reset
```

### Step 5: Verify
Reboot device into OS, enable Developer Options, and confirm **OEM unlocking / Bootloader Unlocked**.
