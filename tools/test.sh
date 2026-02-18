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

# Launch MAME in the background
mame x68000 \
    -flop1 "$BOOT_DISK" \
    -window \
    -skip_gameinfo \
    -nomouse &
MAME_PID=$!

# Wait for MAME window to appear, then move the mouse into it.
# MAME's warning screen is dismissed by any input event, including mouse movement.
for i in $(seq 1 30); do
    sleep 0.5
    WID=$(xdotool search --pid "$MAME_PID" 2>/dev/null | head -1)
    if [ -n "$WID" ]; then
        echo "Found MAME window, dismissing warning..."
        sleep 0.5
        xdotool mousemove --window "$WID" 200 200
        sleep 0.1
        xdotool mousemove --window "$WID" 100 100
        break
    fi
done

wait "$MAME_PID"
echo ""
echo "Done."
