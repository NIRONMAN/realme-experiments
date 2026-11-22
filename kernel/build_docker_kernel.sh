#!/bin/bash
set -e

SOURCE_DIR="/home/niro/Projects/realme-experiments/kernel/source"
TOOLCHAIN_DIR="/home/niro/Projects/realme-experiments/kernel/toolchain/proton-clang"
OUT_DIR="$SOURCE_DIR/out"

echo "=== Building Docker-Enabled Linux 4.14 Kernel for Realme 8 (nashc) ==="
cd "$SOURCE_DIR"

export ARCH=arm64
export SUBARCH=arm64
export CC="$TOOLCHAIN_DIR/bin/clang"
export HOSTCC="gcc -B/usr/bin/"
export HOSTLD="ld"
export CROSS_COMPILE="$TOOLCHAIN_DIR/bin/aarch64-linux-gnu-"
export CROSS_COMPILE_ARM32="$TOOLCHAIN_DIR/bin/arm-linux-gnueabi-"
export CROSS_COMPILE_COMPAT="$TOOLCHAIN_DIR/bin/arm-linux-gnueabi-"
export LD_COMPAT="$TOOLCHAIN_DIR/bin/arm-linux-gnueabi-ld"
export CLANG_TRIPLE="aarch64-linux-gnu-"

# Generate config
echo "[*] Generating .config from lineage-nashc_defconfig..."
make O=out ARCH=arm64 CC="$CC" HOSTCC="$HOSTCC" CROSS_COMPILE="$CROSS_COMPILE" CROSS_COMPILE_ARM32="$CROSS_COMPILE_ARM32" lineage-nashc_defconfig

# Compile kernel Image.gz
CORES=$(nproc)
echo "[*] Compiling kernel with $CORES threads..."
make O=out ARCH=arm64 CC="$CC" HOSTCC="$HOSTCC" CROSS_COMPILE="$CROSS_COMPILE" CROSS_COMPILE_ARM32="$CROSS_COMPILE_ARM32" CROSS_COMPILE_COMPAT="$CROSS_COMPILE_COMPAT" LD_COMPAT="$LD_COMPAT" -j"$CORES" Image.gz dtbs

echo "[+] Kernel compiled successfully!"
ls -lh "$OUT_DIR/arch/arm64/boot/Image.gz"
