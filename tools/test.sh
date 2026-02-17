#!/bin/bash
# X68000 Test Harness
# Boots the X68000 in MAME with the development disk

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BOOT_DISK="$SCRIPT_DIR/../MasterDisk_V3.xdf"

if [ ! -f "$BOOT_DISK" ]; then
    echo "Error: Boot disk not found: $BOOT_DISK"
    exit 1
fi

echo "Booting X68000 with disk: $BOOT_DISK"
echo ""

mame x68000 \
    -flop1 "$BOOT_DISK" \
    -window \
    -skip_gameinfo

echo ""
echo "Done."
