#!/bin/bash
# X68000 Headless Automated Test
# Runs without GUI using MAME's headless mode

set -e

cd "$(dirname "$0")/.."

BOOT_DISK="MasterDisk_V3.xdf"
PROGRAM="build/bin/helloa.x"
TEST_AUTOEXEC="tests/autoexec_test.bat"
BACKUP_AUTOEXEC="autoexec_backup.bat"
TEST_RESULT="test_result.txt"

echo "=========================================="
echo "X68000 Headless Automated Test"
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
rm -f "$TEST_RESULT" test_screenshot.png mame_output.log 2>/dev/null || true

echo "Step 1: Backing up original AUTOEXEC.BAT..."
mcopy -i "$BOOT_DISK" ::AUTOEXEC.BAT "$BACKUP_AUTOEXEC" 2>/dev/null || {
    echo "Warning: Could not backup AUTOEXEC.BAT"
}

echo "Step 2: Installing test AUTOEXEC.BAT (auto-runs program)..."
mcopy -i "$BOOT_DISK" -o "$TEST_AUTOEXEC" ::AUTOEXEC.BAT

echo "Step 3: Ensuring program is installed on boot disk..."
mcopy -i "$BOOT_DISK" -o "$PROGRAM" ::HELLOA.X

echo "Step 4: Running MAME in headless mode with validation..."
echo ""
echo "  - Running without display (headless)"
echo "  - Boot time: ~30 seconds (floppy is slow)"
echo "  - Program execution: ~5 seconds"
echo "  - Total runtime: 45 seconds"
echo ""

# Run MAME in headless mode
# -video soft: software rendering (works without display)
# -sound none: no sound output
# -seconds_to_run: run for specified time then exit
# -script: run Lua validation
# Note: NOT using -nothrottle to ensure proper timing
# Note: Using 'xvfb-run' to provide virtual display if available
if command -v xvfb-run &> /dev/null; then
    echo "  Using Xvfb for virtual display..."
    xvfb-run -a mame x68000 \
        -flop1 "$BOOT_DISK" \
        -window \
        -skip_gameinfo \
        -script mame/test_comprehensive.lua \
        -seconds_to_run 45 \
        2>&1 | tee mame_output.log
else
    echo "  Running with software video (no Xvfb)..."
    mame x68000 \
        -flop1 "$BOOT_DISK" \
        -video soft \
        -sound none \
        -skip_gameinfo \
        -script mame/test_comprehensive.lua \
        -seconds_to_run 45 \
        2>&1 | tee mame_output.log
fi

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

# Extract validation results from MAME output
if grep -q "TEST PASSED" mame_output.log; then
    echo "✓ TEST PASSED!"
    echo ""
    echo "Graphics output validated successfully:"
    grep "checks passed" mame_output.log | tail -1
    echo ""
    echo "Program executed correctly and drew the expected colored rectangles."
    exit 0
elif grep -q "TEST FAILED" mame_output.log; then
    echo "✗ TEST FAILED!"
    echo ""
    echo "Graphics validation failed:"
    grep "checks passed" mame_output.log | tail -1 || echo "No validation data found"
    echo ""
    echo "Program did not produce expected output."
    echo "Check mame_output.log for details."
    exit 1
else
    echo "✗ TEST ERROR!"
    echo ""
    echo "Test validation did not complete properly."
    echo "Checking for errors in output:"
    echo ""
    grep -i "error\|fail" mame_output.log | head -10 || echo "No specific errors found"
    echo ""
    echo "Last 20 lines of output:"
    tail -20 mame_output.log
    exit 1
fi
