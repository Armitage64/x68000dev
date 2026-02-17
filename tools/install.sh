#!/bin/bash
# X68000 Install Script
# Installs the compiled program to the boot disk

set -e

cd "$(dirname "$0")/.."

PROGRAM="${1:-build/bin/program.x}"
BOOT_DISK="MasterDisk_V3.xdf"

if [ ! -f "$PROGRAM" ]; then
    echo "Error: Program not found: $PROGRAM"
    echo "Run 'make all' first"
    exit 1
fi

if [ ! -f "$BOOT_DISK" ]; then
    echo "Error: Boot disk not found: $BOOT_DISK"
    exit 1
fi

echo "Installing $PROGRAM to $BOOT_DISK..."

# Copy program to boot disk (overwrite if exists)
mcopy -i "$BOOT_DISK" -o "$PROGRAM" ::PROGRAM.X

echo "Installation complete!"
echo "Contents of boot disk:"
mdir -i "$BOOT_DISK" ::
