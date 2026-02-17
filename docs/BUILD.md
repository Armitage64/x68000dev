# X68000 Build System Guide

This document explains the build system for X68000 development.

## Overview

The build system uses:
- **GNU Make** - Build automation
- **m68k-linux-gnu-gcc** - C compiler for Motorola 68000
- **m68k-linux-gnu-as** - Assembler
- **m68k-linux-gnu-ld** - Linker
- **m68k-linux-gnu-objcopy** - Binary conversion
- **mtools** - Floppy disk image manipulation

## Quick Start

```bash
# Build everything
make all

# Clean build artifacts
make clean

# Build and test
make test

# Just install to boot disk
make install
```

## Build Process

### 1. Compilation

Source files in `src/` are compiled to object files:

```bash
m68k-linux-gnu-gcc -m68000 -O2 -Wall -Wextra -Iinclude \
    -fomit-frame-pointer -nostdlib -ffreestanding \
    -c src/main.c -o build/obj/main.o
```

**Flags explained:**
- `-m68000` - Target Motorola 68000 CPU
- `-O2` - Optimize for size and speed
- `-Wall -Wextra` - Enable warnings
- `-Iinclude` - Include directory for headers
- `-fomit-frame-pointer` - Save register space
- `-nostdlib` - Don't link standard library
- `-ffreestanding` - Bare-metal target

### 2. Assembly

Assembly files (`.s`) are assembled:

```bash
m68k-linux-gnu-as -m68000 -o build/obj/start.o src/start.s
```

### 3. Linking

Object files are linked using the linker script:

```bash
m68k-linux-gnu-ld -T x68k.ld -nostdlib \
    -o build/bin/program.x.elf \
    build/obj/start.o build/obj/main.o
```

The linker script (`x68k.ld`) defines:
- Entry point: `_start`
- Load address: `0x6800` (Human68k standard)
- Memory layout: `.text`, `.rodata`, `.data`, `.bss`

### 4. Binary Conversion

The ELF file is converted to raw binary:

```bash
m68k-linux-gnu-objcopy -O binary \
    build/bin/program.x.elf \
    build/bin/program.x
```

This creates a Human68k-compatible `.X` executable.

### 5. Installation to Boot Disk

The program is copied to the floppy disk image:

```bash
mcopy -i MasterDisk_V3.xdf -o build/bin/program.x ::PROGRAM.X
```

**mtools flags:**
- `-i` - Disk image file
- `-o` - Overwrite if exists
- `::` - Root directory of disk

## Directory Structure

```
x68000dev/
├── src/           - Source code (.c and .s files)
├── include/       - Header files (.h)
├── build/         - Build output (gitignored)
│   ├── obj/       - Object files (.o)
│   └── bin/       - Final binaries (.x and .elf)
├── assets/        - Game resources (graphics, music)
├── tools/         - Build scripts
├── Makefile       - Build rules
└── x68k.ld        - Linker script
```

## Makefile Targets

### `make all`
Compiles source code, links, converts to binary, and installs to boot disk.

### `make clean`
Removes all build artifacts (`build/` directory).

### `make install`
Copies the built program to the boot disk without rebuilding.

### `make test`
Builds, installs, and runs the program in MAME.

## Customization

### Adding Source Files

Just create `.c` or `.s` files in `src/` or subdirectories. The Makefile automatically finds them using wildcards:

```makefile
C_SRCS = $(wildcard $(SRCDIR)/*.c $(SRCDIR)/*/*.c)
ASM_SRCS = $(wildcard $(SRCDIR)/*.s $(SRCDIR)/*/*.s)
```

### Adding Header Files

Place `.h` files in `include/`. They're automatically included via `-Iinclude`.

### Changing Compiler Flags

Edit the `CFLAGS` variable in `Makefile`:

```makefile
CFLAGS = -m68000 -O2 -Wall -Wextra -Iinclude \
         -fomit-frame-pointer -nostdlib -ffreestanding
```

**For debugging:** Add `-g` for debug symbols, change `-O2` to `-O0`:

```makefile
CFLAGS = -m68000 -O0 -g -Wall -Wextra -Iinclude \
         -fomit-frame-pointer -nostdlib -ffreestanding
```

### Changing the Output Name

Edit the `TARGET` variable in `Makefile`:

```makefile
TARGET = $(BINDIR)/mygame.x
```

And update the install target:

```makefile
install: $(TARGET)
	mcopy -i $(BOOT_DISK) -o $(TARGET) ::MYGAME.X
```

## Linker Script Explained

The `x68k.ld` file defines the memory layout:

```ld
MEMORY
{
    /* Human68k loads programs at 0x00006800 */
    ram : ORIGIN = 0x00006800, LENGTH = 1M
}
```

**Sections:**
- `.text` - Code (starts at 0x6800)
- `.rodata` - Read-only data (strings, constants)
- `.data` - Initialized data
- `.bss` - Uninitialized data (zero-filled)

## Debugging Build Issues

### "undefined reference to `_start`"

Ensure `src/start.s` defines `_start`:

```assembly
.globl _start
_start:
    ...
```

### "undefined reference to `main`"

Ensure `src/main.c` defines `main()`:

```c
void main() {
    ...
}
```

### "relocation truncated to fit"

The program is too large. Try:
- Reduce code size
- Enable optimizations (-O2 or -Os)
- Remove unused code

### "No such file or directory"

Build directories don't exist. Run:

```bash
make clean
make all
```

The Makefile should auto-create directories.

## Advanced: Manual Build

You can build manually without Make:

```bash
# Compile
m68k-linux-gnu-gcc -m68000 -O2 -Wall -nostdlib -ffreestanding \
    -c src/main.c -o build/obj/main.o

m68k-linux-gnu-as -m68000 -o build/obj/start.o src/start.s

# Link
m68k-linux-gnu-ld -T x68k.ld -nostdlib \
    -o build/bin/program.x.elf \
    build/obj/start.o build/obj/main.o

# Convert to binary
m68k-linux-gnu-objcopy -O binary \
    build/bin/program.x.elf build/bin/program.x

# Install
mcopy -i MasterDisk_V3.xdf -o build/bin/program.x ::PROGRAM.X
```

## Next Steps

- Read [TESTING.md](TESTING.md) - Learn about testing in MAME
- Read [DEBUGGING.md](DEBUGGING.md) - Learn about debugging
- Read [X68000_GUIDE.md](X68000_GUIDE.md) - Learn X68000 programming
