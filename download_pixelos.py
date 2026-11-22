#!/usr/bin/env python3
import os
import sys
import time
import urllib.request
import hashlib

URL = "https://downloads.sourceforge.net/project/pixelos-nashc/PixelOS_nashc-13.0-20231216-1529.zip"
TARGET = "/home/niro/Projects/realme-experiments/PixelOS_nashc-13.0-20231216-1529.zip"
EXPECTED_SHA = "9fcdc80873155904e6ca0c8b0d596d8fc3801e515127647cb426928b15d81738"
TOTAL_BYTES = 1756586248

def verify():
    if not os.path.exists(TARGET):
        return False
    if os.path.getsize(TARGET) != TOTAL_BYTES:
        return False
    print("Verifying SHA256...", flush=True)
    h = hashlib.sha256()
    with open(TARGET, "rb") as f:
        while chunk := f.read(4 * 1024 * 1024):
            h.update(chunk)
    digest = h.hexdigest()
    print(f"Calculated: {digest}", flush=True)
    return digest.lower() == EXPECTED_SHA.lower()

def download():
    if verify():
        print("PixelOS already fully downloaded and verified!")
        return

    while True:
        existing = os.path.getsize(TARGET) if os.path.exists(TARGET) else 0
        if existing == TOTAL_BYTES:
            if verify():
                print("Download complete and verified!")
                break
            else:
                print("Size matches but SHA mismatch! Restarting download...")
                os.remove(TARGET)
                existing = 0

        print(f"Downloading PixelOS from byte {existing}/{TOTAL_BYTES} ({existing/(1024*1024):.1f} MB)...", flush=True)
        headers = {
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        }
        if existing > 0:
            headers["Range"] = f"bytes={existing}-"

        try:
            req = urllib.request.Request(URL, headers=headers)
            with urllib.request.urlopen(req, timeout=30) as resp, open(TARGET, "ab" if existing > 0 else "wb") as f:
                mode = "ab" if existing > 0 else "wb"
                downloaded = existing
                start_t = time.time()
                last_report = start_t
                last_bytes = downloaded

                while True:
                    chunk = resp.read(256 * 1024)
                    if not chunk:
                        break
                    f.write(chunk)
                    downloaded += len(chunk)

                    now = time.time()
                    if now - last_report >= 5:
                        speed = (downloaded - last_bytes) / (now - last_report) / (1024 * 1024)
                        pct = (downloaded / TOTAL_BYTES) * 100
                        print(f"[{pct:.1f}%] {downloaded/(1024*1024):.1f}/{TOTAL_BYTES/(1024*1024):.1f} MB ({speed:.2f} MB/s)", flush=True)
                        last_report = now
                        last_bytes = downloaded

            if verify():
                print("PixelOS verified successfully!")
                break
        except Exception as e:
            print(f"Download interrupted ({e}), resuming in 3 seconds...", flush=True)
            time.sleep(3)

if __name__ == "__main__":
    download()
