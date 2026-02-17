#!/bin/bash
# X68000 Debug Script
# Launches MAME with GDB stub for debugging

set -e

cd "$(dirname "$0")/.."

BOOT_DISK="MasterDisk_V3.xdf"

if [ ! -f "$BOOT_DISK" ]; then
    echo "Error: Boot disk not found: $BOOT_DISK"
    exit 1
fi

echo "========================================"
echo "Starting MAME with GDB stub on port 1234"
echo "========================================"
echo ""
echo "In another terminal, run:"
echo "  gdb-multiarch -x mame/debug_session.gdb"
echo ""
echo "GDB Commands:"
echo "  break main       - Set breakpoint at main"
echo "  continue         - Run to breakpoint"
echo "  step             - Step into"
echo "  next             - Step over"
echo "  backtrace        - Stack trace"
echo "  info registers   - Show CPU registers"
echo "  x/16x 0xC00000   - Examine GVRAM"
echo ""
echo "Press Ctrl+C to stop MAME"
echo "========================================"
echo ""

mame x68000 \
    -flop1 "$BOOT_DISK" \
    -window \
    -debug \
    -debugger gdbstub \
    -debugger_port 1234
