#!/usr/bin/env python3
import os
import sys
import time
import urllib.request
import hashlib
from concurrent.futures import ThreadPoolExecutor

SOURCE_URL = "https://downloads.sourceforge.net/project/pixelos-nashc/PixelOS_nashc-13.0-20231216-1529.zip"
TARGET = "/home/niro/Projects/realme-experiments/PixelOS_nashc-13.0-20231216-1529.zip"
EXPECTED_SHA = "9fcdc80873155904e6ca0c8b0d596d8fc3801e515127647cb426928b15d81738"
NUM_WORKERS = 8

def verify_file(path):
    if not os.path.exists(path):
        return False
    print("Verifying SHA-256 checksum...", flush=True)
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(4 * 1024 * 1024):
            h.update(chunk)
    digest = h.hexdigest()
    print(f"Calculated: {digest}", flush=True)
    return digest.lower() == EXPECTED_SHA.lower()

def download_chunk(final_url, part_file, start, end):
    existing = os.path.getsize(part_file) if os.path.exists(part_file) else 0
    cur_start = start + existing
    if cur_start > end:
        return True

    while cur_start <= end:
        headers = {
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36",
            "Range": f"bytes={cur_start}-{end}"
        }
        try:
            req = urllib.request.Request(final_url, headers=headers)
            with urllib.request.urlopen(req, timeout=25) as resp, open(part_file, "ab" if cur_start > start else "wb") as f:
                while True:
                    data = resp.read(256 * 1024)
                    if not data:
                        break
                    f.write(data)
                    cur_start += len(data)
        except Exception as e:
            time.sleep(2)
            existing = os.path.getsize(part_file) if os.path.exists(part_file) else 0
            cur_start = start + existing

    return True

def main():
    if verify_file(TARGET):
        print("PixelOS is already fully downloaded and verified!")
        return

    print("Resolving final download URL from SourceForge...", flush=True)
    req = urllib.request.Request(SOURCE_URL, headers={"User-Agent": "curl/8.0"})
    with urllib.request.urlopen(req) as resp:
        final_url = resp.geturl()
        total_size = int(resp.headers.get("Content-Length", 1756586248))

    print(f"Total size: {total_size / (1024*1024):.1f} MB across {NUM_WORKERS} workers.", flush=True)
    chunk_size = total_size // NUM_WORKERS
    tasks = []
    part_files = []

    for i in range(NUM_WORKERS):
        start = i * chunk_size
        end = total_size - 1 if i == NUM_WORKERS - 1 else (i + 1) * chunk_size - 1
        part_file = f"{TARGET}.part{i}"
        part_files.append(part_file)
        tasks.append((part_file, start, end))

    print("Launching parallel worker threads...", flush=True)
    start_time = time.time()

    with ThreadPoolExecutor(max_workers=NUM_WORKERS) as executor:
        futures = [executor.submit(download_chunk, final_url, pf, s, e) for pf, s, e in tasks]
        
        while not all(f.done() for f in futures):
            time.sleep(3)
            current_bytes = sum(os.path.getsize(pf) for pf in part_files if os.path.exists(pf))
            pct = (current_bytes / total_size) * 100
            elapsed = time.time() - start_time
            speed = (current_bytes / elapsed) / (1024 * 1024) if elapsed > 0 else 0
            print(f"[{pct:.1f}%] {current_bytes/(1024*1024):.1f}/{total_size/(1024*1024):.1f} MB (Speed: {speed:.2f} MB/s)", flush=True)

    print("All chunks downloaded! Merging parts...", flush=True)
    with open(TARGET, "wb") as outfile:
        for pf in part_files:
            with open(pf, "rb") as infile:
                while chunk := infile.read(4 * 1024 * 1024):
                    outfile.write(chunk)
            os.remove(pf)

    if verify_file(TARGET):
        print("PixelOS download 100% complete and verified!")
    else:
        print("ERROR: SHA-256 verification failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
