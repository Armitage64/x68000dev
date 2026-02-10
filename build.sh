#!/bin/bash
# ============================================================================
# Build script for Out Run Music Player (Linux/Mac)
# ============================================================================

echo "Building Out Run Music Player..."

# Set paths to tools (adjust these to your installation)
VASM="vasmm68k_mot"

# Check if VASM is available
if ! command -v $VASM &> /dev/null; then
    echo "ERROR: VASM not found in PATH"
    echo "Please install VASM or update the VASM variable in this script"
    echo ""
    echo "VASM can be downloaded from: http://sun.hasenbraten.de/vasm/"
    exit 1
fi

# Assemble the source
$VASM -Fhunk -o outrun.x -nosym outrun.s

if [ $? -ne 0 ]; then
    echo "ERROR: Assembly failed!"
    exit 1
fi

echo "Build successful! Output: outrun.x"
echo ""
echo "To run in MAME:"
echo "  mame x68000 -ramsize 4M -flop1 outrun.x"
echo ""
echo "Make sure MXDRV.X and the .MDX files are in the same directory!"

exit 0
