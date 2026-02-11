#!/bin/bash
# ============================================================================
# Build script for Out Run Music Player - C Version (Linux/Mac)
# ============================================================================

echo "Building Out Run Music Player (C version)..."

# Set paths to tools (adjust these to your installation)
GCC="human68k-gcc"

# Check if compiler is available
if ! command -v $GCC &> /dev/null; then
    echo "ERROR: $GCC not found in PATH"
    echo "Please install the Human68k cross-compiler toolchain"
    echo ""
    echo "Toolchain can be built from: https://github.com/Lydux/gcc-4.6.2-human68k"
    exit 1
fi

# Compile the C source
$GCC -O2 -Wall -o outrun_c.x outrun.c

if [ $? -ne 0 ]; then
    echo "ERROR: Compilation failed!"
    exit 1
fi

echo "Build successful! Output: outrun_c.x"
echo ""
echo "To run in MAME:"
echo "  mame x68000 -ramsize 4M -flop1 outrun_c.x"
echo ""
echo "Make sure MXDRV.X and the .MDX files are in the same directory!"

exit 0
