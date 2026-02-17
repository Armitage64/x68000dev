#!/bin/bash
# Automated X68000 Test Script
# Runs MAME with Lua validation to verify program execution

set -e

cd "$(dirname "$0")/.."

BOOT_DISK="MasterDisk_V3.xdf"
LUA_SCRIPT="mame/test_simple_vram.lua"

if [ ! -f "$BOOT_DISK" ]; then
    echo "Error: Boot disk not found: $BOOT_DISK"
    exit 1
fi

if [ ! -f "$LUA_SCRIPT" ]; then
    echo "Error: Lua test script not found: $LUA_SCRIPT"
    exit 1
fi

echo "========================================="
echo "X68000 Automated Test"
echo "========================================="
echo ""
echo "This will:"
echo "  1. Boot X68000 in MAME"
echo "  2. Wait for you to dismiss the warning screen"
echo "  3. Automatically wait 100 seconds for boot and execution"
echo "  4. Check VRAM for program activity"
echo "  5. Report test results"
echo ""
echo "Starting test..."
echo ""

# Run MAME with Lua validation
mame x68000 \
    -flop1 "$BOOT_DISK" \
    -window \
    -skip_gameinfo \
    -autoboot_script "$LUA_SCRIPT" 2>&1 | grep -E '\[LUA\]'

echo ""
echo "========================================="
echo "Test complete!"
echo "========================================="
