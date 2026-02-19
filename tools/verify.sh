#!/bin/bash
# X68000 Setup Verification Script
# Checks that everything is properly configured

set -e

cd "$(dirname "$0")/.."

echo "======================================"
echo "X68000 Development Environment Check"
echo "======================================"
echo ""

# Check tools
echo "Checking required tools..."
MISSING=0

if command -v m68k-linux-gnu-gcc &> /dev/null; then
    VERSION=$(m68k-linux-gnu-gcc --version | head -1)
    echo "✓ m68k-linux-gnu-gcc: $VERSION"
else
    echo "✗ m68k-linux-gnu-gcc: NOT FOUND"
    MISSING=1
fi

if command -v mame &> /dev/null; then
    VERSION=$(mame -version 2>&1)
    echo "✓ MAME: $VERSION"
else
    echo "✗ MAME: NOT FOUND"
    MISSING=1
fi

if command -v mcopy &> /dev/null; then
    echo "✓ mtools (mcopy): Found"
else
    echo "✗ mtools (mcopy): NOT FOUND"
    MISSING=1
fi

if command -v gdb-multiarch &> /dev/null; then
    echo "✓ gdb-multiarch: Found"
else
    echo "✗ gdb-multiarch: NOT FOUND"
    MISSING=1
fi

echo ""

# Check boot disk
echo "Checking boot disk..."
if [ -f "MasterDisk_V3.xdf" ]; then
    SIZE=$(ls -lh MasterDisk_V3.xdf | awk '{print $5}')
    echo "✓ Boot disk: MasterDisk_V3.xdf ($SIZE)"
else
    echo "✗ Boot disk: NOT FOUND"
    MISSING=1
fi

echo ""

# Check X68000 ROMs
echo "Checking X68000 BIOS ROMs..."
if mame -verifyroms x68000 2>&1 | grep -q "is good"; then
    echo "✓ X68000 BIOS ROMs: Verified"
else
    echo "✗ X68000 BIOS ROMs: NOT VERIFIED"
    echo "  Run: mame -verifyroms x68000"
    echo "  ROMs must be placed in ~/.mame/roms/x68000/"
    MISSING=1
fi

echo ""

# Check build
echo "Checking build..."
if [ -f "build/bin/helloa.x" ]; then
    SIZE=$(ls -lh build/bin/helloa.x | awk '{print $5}')
    echo "✓ Built program: build/bin/helloa.x ($SIZE)"
else
    echo "ℹ Program not built yet"
    echo "  Run: make all"
fi

if [ -f "build/bin/helloa.x.elf" ]; then
    echo "✓ Debug symbols: build/bin/helloa.x.elf"
else
    if [ -f "build/bin/helloa.x" ]; then
        echo "✗ Debug symbols: NOT FOUND"
    fi
fi

echo ""

# Check boot disk contents
echo "Checking program installation..."
if mdir -i MasterDisk_V3.xdf :: 2>/dev/null | grep -q -i "PROGRAM"; then
    echo "✓ HELLOA.X installed on boot disk"
else
    echo "ℹ HELLOA.X not on boot disk yet"
    echo "  Run: make install"
fi

echo ""
echo "======================================"

if [ $MISSING -eq 0 ]; then
    echo "✓ All required tools are installed!"
    echo ""
    echo "Next steps:"
    echo "  1. Build: make all"
    echo "  2. Test: make test"
    echo "  3. Debug: ./tools/debug.sh"
else
    echo "✗ Some required tools are missing!"
    echo ""
    echo "Install missing tools:"
    echo "  sudo apt install gcc-m68k-linux-gnu mame mtools gdb-multiarch"
    exit 1
fi

echo "======================================"
