#!/bin/bash
# ============================================================================
# Build script for Out Run Music Player - C Version (Linux/Mac)
# ============================================================================

echo "Building Out Run Music Player (C version)..."

# Set paths to tools (adjust these to your installation)
GCC="human68k-gcc"
OBJCOPY="human68k-objcopy"

# Check if compiler is available
if ! command -v $GCC &> /dev/null; then
    echo "ERROR: $GCC not found in PATH"
    echo "Please install the Human68k cross-compiler toolchain"
    echo ""
    echo "Toolchain can be built from: https://github.com/Lydux/gcc-4.6.2-human68k"
    exit 1
fi

# Check if objcopy is available
if ! command -v $OBJCOPY &> /dev/null; then
    echo "ERROR: $OBJCOPY not found in PATH"
    echo "Please install binutils-2.22-human68k"
    exit 1
fi

# Compile and link the C source
echo "Compiling..."
$GCC -m68000 -O2 -Wall -o outrun.elf outrun.c -ldos -liocs

if [ $? -ne 0 ]; then
    echo "ERROR: Compilation failed!"
    exit 1
fi

# Convert to X68000 .X format
echo "Converting to X68000 format..."
$OBJCOPY -O xfile outrun.elf outrun.x

if [ $? -ne 0 ]; then
    echo "ERROR: Conversion to X68000 format failed!"
    exit 1
fi

# Clean up intermediate file
rm -f outrun.elf

echo "Build successful! Output: outrun.x"
echo ""
echo "To run in MAME:"
echo "  mame x68000 -ramsize 4M -flop1 outrun.x"
echo ""
echo "Make sure MXDRV.X and the .MDX files are in the same directory!"

exit 0
