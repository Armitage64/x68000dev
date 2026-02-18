#!/bin/bash
# X68000 GUI Automated Test
# Requires display but fully automated via AUTOEXEC.BAT and Lua validation

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

# Ensure DISPLAY is set for MAME and xdotool
if [ -z "$DISPLAY" ]; then
    export DISPLAY=:10.0
fi

BOOT_DISK="$SCRIPT_DIR/../MasterDisk_V3.xdf"
PROGRAM="build/bin/program.x"
TEST_AUTOEXEC="tests/autoexec_test.bat"
BACKUP_AUTOEXEC="autoexec_backup.bat"

echo "=========================================="
echo "X68000 GUI Automated Test"
echo "=========================================="
echo ""

# Check prerequisites
if [ ! -f "$BOOT_DISK" ]; then
    echo "ERROR: Boot disk not found: $BOOT_DISK"
    exit 1
fi

if [ ! -f "$PROGRAM" ]; then
    echo "ERROR: Program not built. Run 'make all' first."
    exit 1
fi

# Clean up previous test results
rm -f test_result.txt test_screenshot.png mame_output.log 2>/dev/null || true

echo "Step 1: Backing up original AUTOEXEC.BAT..."
mcopy -i "$BOOT_DISK" ::AUTOEXEC.BAT "$BACKUP_AUTOEXEC" 2>/dev/null || true

echo "Step 2: Installing test AUTOEXEC.BAT (auto-runs program)..."
mcopy -i "$BOOT_DISK" -o "$TEST_AUTOEXEC" ::AUTOEXEC.BAT

echo "Step 3: Ensuring program is installed on boot disk..."
mcopy -i "$BOOT_DISK" -o "$PROGRAM" ::PROGRAM.X

echo "Step 4: Running MAME with GUI and automated validation..."
echo ""
echo "  - Boot time: ~30 seconds (floppy is slow)"
echo "  - AUTOEXEC.BAT will auto-run program"
echo "  - Lua script will validate after 35 seconds"
echo "  - MAME will auto-close after test"
echo ""
echo "  NOTE: MAME window will open. Do NOT interact with it."
echo "        The test is fully automated."
echo ""

# Pre-acknowledge the MAME warning by setting 'warned' to a far-future timestamp.
# MAME shows the warning when launched > warned. By setting warned >> launched,
# MAME will see no new warning to show and boot directly.
CFG_FILE="$HOME/.mame/cfg/x68000.cfg"
if [ -f "$CFG_FILE" ]; then
    sed -i 's/warned="[0-9]*"/warned="9999999999"/' "$CFG_FILE"
    echo "  Pre-acknowledged MAME warning in cfg"
fi

# Run MAME in background so we can dismiss the warning screen
mame x68000 \
    -flop1 "$BOOT_DISK" \
    -window \
    -skip_gameinfo \
    -nomouse \
    -script mame/test_hello.lua \
    > mame_output.log 2>&1 &
MAME_PID=$!

# Wait for MAME window to appear, then dismiss the warning screen.
# Uses dismiss_warning.py which injects input at kernel level via /dev/uinput,
# bypassing any X11 synthetic event filtering MAME might apply.
# Also focuses the window first so MAME receives the event.
echo "Waiting for MAME window to dismiss warning..."
WID=""
for i in $(seq 1 20); do
    sleep 0.5
    WID=$(xdotool search --pid "$MAME_PID" 2>/dev/null | head -1)
    if [ -n "$WID" ]; then
        echo "  Found MAME window (attempt $i)"
        break
    fi
done
if [ -z "$WID" ]; then
    echo "  ERROR: MAME window not found after 10s - aborting"
    kill "$MAME_PID" 2>/dev/null || true
    exit 1
fi

# Wait for the warning screen to render, then dismiss it with a mouse move
echo "  Waiting for warning screen to render..."
sleep 3.0
echo "  Dismissing warning screen..."
xdotool mousemove --window "$WID" 200 200 2>/dev/null || true
sleep 0.1
xdotool mousemove --window "$WID" 100 100 2>/dev/null || true

# Monitor for boot progress: if PC stays in BIOS after 2 minutes, something is wrong
echo "Waiting for MAME to complete (~70 seconds for boot + test)..."
TIMEOUT=150
ELAPSED=0
while kill -0 "$MAME_PID" 2>/dev/null; do
    sleep 2
    ELAPSED=$((ELAPSED + 2))
    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
        echo "  ERROR: MAME still running after ${TIMEOUT}s - killing (stuck on warning?)"
        kill "$MAME_PID" 2>/dev/null || true
        break
    fi
done
wait "$MAME_PID" 2>/dev/null || true

echo ""
echo "Step 5: Restoring original AUTOEXEC.BAT..."
if [ -f "$BACKUP_AUTOEXEC" ]; then
    mcopy -i "$BOOT_DISK" -o "$BACKUP_AUTOEXEC" ::AUTOEXEC.BAT
    rm "$BACKUP_AUTOEXEC"
fi

echo ""
echo "=========================================="
echo "Test Results"
echo "=========================================="
echo ""

# Check results from MAME output
if grep -q "TEST PASSED" mame_output.log; then
    echo "✓ TEST PASSED!"
    echo ""
    grep "TEST PASSED\|Output detected\|TVRAM\|GVRAM" mame_output.log | grep '^\[LUA\]' | tail -5
    exit 0
elif grep -q "TEST PARTIAL" mame_output.log; then
    echo "⚠ TEST PARTIAL - program loaded but no screen output"
    echo ""
    grep '\[LUA\]' mame_output.log | tail -10
    exit 1
elif grep -q "TEST FAILED" mame_output.log; then
    echo "✗ TEST FAILED!"
    echo ""
    grep '\[LUA\]' mame_output.log | tail -10
    exit 1
else
    echo "✗ TEST ERROR - validation did not complete"
    echo ""
    echo "Last 20 lines of MAME output:"
    tail -20 mame_output.log
    exit 1
fi
