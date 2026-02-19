#!/bin/bash
# Create proper Human68k .X executable from raw binary
# Human68k .X format requires position-independent code

set -e

INPUT="${1:-build/bin/helloc.elf}"
OUTPUT="${2:-build/bin/helloc.x}"

if [ ! -f "$INPUT" ]; then
    echo "Error: Input file not found: $INPUT"
    exit 1
fi

echo "Creating Human68k .X executable..."

# For Human68k, we need position-independent code
# The simplest approach: create raw binary starting at 0
# Human68k will load it at 0x6800

# Extract just the .text section as raw binary
m68k-linux-gnu-objcopy -O binary -j .text "$INPUT" "$OUTPUT.tmp1"

# Create a simple wrapper with proper entry
cat > /tmp/x68k_wrapper.s << 'EOF'
    .text
    .org 0

    # Human68k loads at 0x6800
    # Jump to our code (which will be appended)
    bra.w   start

    # Padding for alignment
    .align 4

start:
    # Code will be inserted here by combining files
EOF

# Assemble wrapper
m68k-linux-gnu-as -m68000 /tmp/x68k_wrapper.s -o /tmp/wrapper.o
m68k-linux-gnu-ld -Ttext=0 -o /tmp/wrapper.elf /tmp/wrapper.o
m68k-linux-gnu-objcopy -O binary /tmp/wrapper.elf "$OUTPUT.tmp2"

# Combine wrapper + code
cat "$OUTPUT.tmp2" "$OUTPUT.tmp1" > "$OUTPUT"

# Cleanup
rm -f "$OUTPUT.tmp1" "$OUTPUT.tmp2" /tmp/wrapper.o /tmp/wrapper.elf /tmp/x68k_wrapper.s

SIZE=$(ls -lh "$OUTPUT" | awk '{print $5}')
echo "Created: $OUTPUT ($SIZE)"
