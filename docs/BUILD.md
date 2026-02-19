# X68000 Build System Guide

This document explains the build system for X68000 development.

## Overview

The build system uses:
- **GNU Make** - Build automation
- **vasmm68k_mot** - VASM M68k assembler (assembly programs, native `.X` output)
- **m68k-linux-gnu-gcc** - C compiler for Motorola 68000
- **m68k-linux-gnu-as** - GAS assembler (C runtime startup)
- **m68k-linux-gnu-ld** - Linker
- **m68k-linux-gnu-objcopy** - Raw binary extraction
- **tools/make_xfile.py** - Human68k `.X` header wrapper
- **mtools** - Floppy disk image manipulation

## Quick Start

```bash
# Build all programs (assembly + C)
make all

# Clean build artifacts
make clean

# Install both programs to boot disk
make install

# Interactive MAME session
make test

# Fully automated test (CI-friendly)
make test-auto
```

## Build Paths

There are two separate build paths — one for the assembly hello world and one
for the C hello world.

---

### Assembly path: `src/hello.s` → `build/bin/helloa.x`

VASM assembles directly to a native Human68k `.X` executable in one step:

```bash
./tools/vasmm68k_mot -Fxfile -nosym -o build/bin/helloa.x src/hello.s
```

**Flags:**
- `-Fxfile` — output in Human68k `.X` format (header + code + data)
- `-nosym` — strip symbol table (smaller output)

---

### C path: `src/hello_c.c` → `build/bin/hello_c.x`

GCC cannot produce Human68k `.X` files directly; it outputs Linux ELF. The
pipeline converts ELF to `.X` in three steps after compilation:

#### 1. Compile C source

```bash
m68k-linux-gnu-gcc \
    -m68000 -nostdlib -ffreestanding -fno-builtin \
    -fomit-frame-pointer -mpcrel \
    -c src/hello_c.c -o build/obj/hello_c.o
```

**Key flags:**
- `-m68000` — target the base 68000 (no 68020+ instructions)
- `-nostdlib -ffreestanding -fno-builtin` — bare-metal, no libc
- `-mpcrel` — **critical**: emit PC-relative data references instead of absolute
  addresses. Without this, GCC generates `pea $6826` (absolute); the program
  only works if loaded at exactly the linker origin. With `-mpcrel`, GCC emits
  `pea (offset,PC)`, which resolves correctly at whatever address Human68k
  chooses to load the program.

#### 2. Assemble C runtime startup

```bash
m68k-linux-gnu-as -m68000 src/crt0.s -o build/obj/crt0.o
```

`src/crt0.s` provides the `_start` entry point required by the linker. It calls
`main()` via a PC-relative `jsr main(%pc)` and then executes `_EXIT` (`dc.w
$FF00`):

```asm
    .global _start
    .text
_start:
    jsr     main(%pc)   /* PC-relative call — position independent */
    .word   0xFF00      /* DOS _EXIT */
```

#### 3. Link to ELF

```bash
m68k-linux-gnu-ld -T x68k.ld \
    -o build/bin/hello_c.elf \
    build/obj/crt0.o build/obj/hello_c.o
```

`x68k.ld` sets the linker origin to `0x6800` (Human68k's typical program load
address). Because all code uses PC-relative addressing (`-mpcrel`), the actual
runtime load address does not have to be `0x6800` — the linker origin is only
used to assign symbol offsets; the resulting code is position-independent.

#### 4. Extract raw binary

```bash
m68k-linux-gnu-objcopy -O binary \
    build/bin/hello_c.elf build/bin/hello_c.bin
```

Strips the ELF container, leaving only the raw machine code and data.

#### 5. Wrap with Human68k `.X` header

```bash
python3 tools/make_xfile.py build/bin/hello_c.bin build/bin/hello_c.x
```

`make_xfile.py` prepends a 64-byte `.X` header:

| Offset | Field        | Value                          |
|--------|-------------|-------------------------------|
| 0x00   | Magic       | `HU` (0x48, 0x55)              |
| 0x04   | Base address | `0x00000000` (relocatable)    |
| 0x08   | Entry offset | `0x00000000` (start of text)  |
| 0x0C   | text_size   | size of raw binary payload     |
| 0x10+  | data/bss/…  | `0` (all in text section)      |

With `base_address = 0`, Human68k treats the program as relocatable and loads
it at the first available address in user memory (typically `0x7000`–`0x8000`
depending on what drivers are resident). The PC-relative code runs correctly
regardless of that address.

#### 6. Install both programs

```bash
mcopy -i MasterDisk_V3.xdf -o build/bin/helloa.x ::HELLOA.X
mcopy -i MasterDisk_V3.xdf -o build/bin/hello_c.x ::HELLO_C.X
```

## Makefile Targets

### `make all`
Builds both `build/bin/helloa.x` (assembly) and `build/bin/hello_c.x` (C).

### `make clean`
Removes all build artifacts (`build/` directory).

### `make install`
Copies both binaries to the boot disk:
- `build/bin/helloa.x` → `::HELLOA.X`
- `build/bin/hello_c.x` → `::HELLO_C.X`

### `make test`
Installs both programs and opens an interactive MAME session. At the `A>` prompt
you can run either program manually: `A:HELLOA.X` or `A:HELLO_C.X`.

### `make test-auto`
Runs a fully automated MAME test: installs both programs, boots, runs the test
`AUTOEXEC.BAT` (which executes both sequentially), validates TVRAM output, and
exits with a pass/fail code.

## Linker Script

`x68k.ld` sets the linker origin to `0x6800` — Human68k's typical first user
program address. The C program uses `-mpcrel` throughout, so the origin only
affects symbol offsets in the ELF; the resulting binary is position-independent
and runs wherever Human68k loads it.

```ld
MEMORY { ram : ORIGIN = 0x00006800, LENGTH = 1M }

SECTIONS {
    .text  0x00006800 : { *(.text.startup) *(.text) *(.text.*) } > ram
    .rodata            : { *(.rodata) *(.rodata.*) }              > ram
    .data              : { *(.data)   *(.data.*)   }              > ram
    .bss               : { *(.bss)    *(.bss.*)    *(COMMON) }    > ram
}
```

## Debugging Build Issues

### "Illegal instruction" on the X68000

Almost always a position-dependency bug. If you omit `-mpcrel`, GCC emits
absolute addresses (`pea $6826`). When Human68k loads the program at a
different address (because `base_address = 0` in the `.X` header makes it
relocatable), those absolute references point into random memory and execution
goes off the rails.

Check: `m68k-linux-gnu-objdump -d build/bin/hello_c.elf | grep pea`
- Bad: `pea $6826` — absolute, will break if not loaded at exactly 0x6800
- Good: `pea %pc@(6826)` — PC-relative, works at any load address

### "undefined reference to `_start`"

The C program needs `src/crt0.s` to be compiled and linked first:

```bash
m68k-linux-gnu-as -m68000 src/crt0.s -o build/obj/crt0.o
m68k-linux-gnu-ld -T x68k.ld -o ... build/obj/crt0.o build/obj/hello_c.o
```

### "relocation truncated to fit"

A PC-relative displacement overflowed 16 bits — code and data are more than
32 KB apart. For small programs this should not happen; check that no large
buffers or arrays are in `.bss` or `.data`.

## Next Steps

- Read [TESTING.md](TESTING.md) - Learn about testing in MAME
- Read [DEBUGGING.md](DEBUGGING.md) - Learn about debugging
- Read [X68000_GUIDE.md](X68000_GUIDE.md) - Learn X68000 programming
