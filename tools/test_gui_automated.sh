#!/bin/bash
# X68000 GUI Automated Test
# Requires display but fully automated via AUTOEXEC.BAT and Lua validation

set -e

cd "$(dirname "$0")/.."

BOOT_DISK="MasterDisk_V3.xdf"
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

# Run MAME with GUI but automated testing
mame x68000 \
    -flop1 "$BOOT_DISK" \
    -window \
    -nomax \
    -resolution 768x512 \
    -skip_gameinfo \
    -script mame/test_comprehensive.lua \
    -seconds_to_run 45 \
    2>&1 | tee mame_output.log

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
    echo "Graphics output validated successfully:"
    grep "checks passed\|GVRAM activity" mame_output.log | tail -2
    echo ""
    echo "Program executed correctly and drew the expected pattern."
    exit 0
elif grep -q "TEST FAILED" mame_output.log; then
    echo "✗ TEST FAILED!"
    echo ""
    echo "Graphics validation failed:"
    grep "GVRAM activity\|checks passed" mame_output.log | tail -2
    echo ""
    echo "Check if:"
    echo "  - AUTOEXEC.BAT ran the program"
    echo "  - Program has correct format"
    echo "  - Enough time for boot and execution"
    exit 1
else
    echo "✗ TEST ERROR!"
    echo ""
    echo "Test validation did not complete."
    echo "Last 20 lines of output:"
    tail -20 mame_output.log
    exit 1
fi
