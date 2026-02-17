#!/bin/bash
# X68000 Test Script
# Runs the program in MAME emulator with the boot disk

set -e

cd "$(dirname "$0")/.."

BOOT_DISK="MasterDisk_V3.xdf"

if [ ! -f "$BOOT_DISK" ]; then
    echo "Error: Boot disk not found: $BOOT_DISK"
    exit 1
fi

# Verify program is on the disk
echo "Checking boot disk contents..."
mdir -i "$BOOT_DISK" :: | grep -i "PROGRAM" | grep -i "X" || {
    echo "Error: PROGRAM.X not found on boot disk"
    echo "Run 'make install' first"
    exit 1
}

echo "Running program in MAME with boot disk: $BOOT_DISK"
echo ""
echo "========================================"
echo "INSTRUCTIONS:"
echo "1. Wait for Human68k prompt (A>)"
echo "2. Type: A:PROGRAM.X"
echo "3. Press Enter"
echo "4. You should see three colored squares"
echo "5. Press Ctrl+C in terminal to exit MAME"
echo "========================================"
echo ""

# Run MAME with boot disk
# Manual test - no Lua script to avoid crashes
mame x68000 \
    -flop1 "$BOOT_DISK" \
    -window \
    -nomax \
    -resolution 768x512 \
    -skip_gameinfo

echo ""
echo "Test complete!"
