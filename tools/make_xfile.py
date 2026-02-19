#!/usr/bin/env python3
"""Wrap a raw m68k binary in a Human68k .X executable header."""
import sys
import struct

def make_xfile(bin_path, out_path):
    with open(bin_path, 'rb') as f:
        payload = f.read()

    header = bytearray(64)
    header[0] = 0x48  # 'H'
    header[1] = 0x55  # 'U'
    # base address = 0 (bytes 0x04-0x07): relocatable; OS chooses load address
    # entry point  = 0 (bytes 0x08-0x0B): offset 0 from load base = _start
    struct.pack_into('>I', header, 0x0C, len(payload))  # text_size
    # data_size, bss_size, reloc_size, sym_size, line_size = 0 (already zero)
    # flags = 0 (already zero)

    with open(out_path, 'wb') as f:
        f.write(bytes(header))
        f.write(payload)

    print(f"Created {out_path}: {len(header) + len(payload)} bytes "
          f"(text={len(payload):#x})")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input.bin> <output.x>")
        sys.exit(1)
    make_xfile(sys.argv[1], sys.argv[2])
