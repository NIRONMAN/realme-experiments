#!/system/bin/sh
# ==============================================================================
# Realme 8 4G (MT6785 / nashc) 24/7 Server Battery & System Guard Daemon
# ==============================================================================
# Features:
# 1. Hardware Charging Cut-Off: Uses /sys/devices/virtual/oplus_chg/battery/mmi_charging_enable
#    - Cycles battery between MIN_SOC (50%) and MAX_SOC (60%) to prevent swelling.
# 2. Kernel Wakelock: Writes to /sys/power/wake_lock to prevent deep sleep / suspend.
# 3. Disables Android Doze (deviceidle).
# 4. Enables Wi-Fi Constantly Awake Mode (CAM) to ensure sub-2ms network latency.
# ==============================================================================

CHG_ENABLE="/sys/devices/virtual/oplus_chg/battery/mmi_charging_enable"
STOP_CHG="/sys/devices/virtual/oplus_chg/battery/stop_charging_enable"
BATT_CAP="/sys/class/power_supply/battery/capacity"
BATT_TEMP="/sys/class/power_supply/battery/temp"

MIN_SOC=50
MAX_SOC=60
MAX_TEMP=420  # 42.0 C in deci-Celsius

echo "[*] Initializing Realme 8 Server Keepalive & Power Management..."

# 1. Prevent CPU sleep / suspend-to-RAM
if [ -w /sys/power/wake_lock ]; then
    echo "realme_server_guard" > /sys/power/wake_lock
    echo "[+] Acquired kernel wake_lock: realme_server_guard"
fi

# 2. Disable Android Doze & idle power restrictions
dumpsys deviceidle disable 2>/dev/null
settings put global stay_on_while_plugged_in 3 2>/dev/null

# 3. Disable Wi-Fi power saving (MediaTek Constantly Awake Mode)
if [ -w /proc/net/wlan/setCAM ]; then
    echo 1 > /proc/net/wlan/setCAM
    echo "[+] Set Wi-Fi Constantly Awake Mode (setCAM = 1)"
fi
if [ -w /proc/net/wlan/autoPerfCfg ]; then
    echo "ForceEnable:1" > /proc/net/wlan/autoPerfCfg
    echo "[+] Enabled Wi-Fi auto performance monitoring"
fi

# Helper functions for charging control
disable_charging() {
    echo 0 > "$CHG_ENABLE" 2>/dev/null || true
    echo 1 > "$STOP_CHG" 2>/dev/null || true
    dumpsys battery set status 4 2>/dev/null || true
}

enable_charging() {
    echo 0 > "$STOP_CHG" 2>/dev/null || true
    echo 1 > "$CHG_ENABLE" 2>/dev/null || true
    dumpsys battery reset 2>/dev/null || true
}

# 4. Continuous battery monitoring loop
echo "[+] Starting Battery Guard monitor loop (Threshold: $MIN_SOC% - $MAX_SOC%)..."
while true; do
    if [ -f "$BATT_CAP" ]; then
        CAP=$(cat "$BATT_CAP" 2>/dev/null)
        TEMP=$(cat "$BATT_TEMP" 2>/dev/null)

        # Thermal protection override
        if [ -n "$TEMP" ] && [ "$TEMP" -ge "$MAX_TEMP" ]; then
            echo "[!] Thermal limit reached (${TEMP} dC). Disabling charging."
            disable_charging
        elif [ -n "$CAP" ]; then
            if [ "$CAP" -ge "$MAX_SOC" ]; then
                disable_charging
            elif [ "$CAP" -le "$MIN_SOC" ]; then
                enable_charging
            fi
        fi
    fi
    sleep 30
done
