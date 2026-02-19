# X68000 Development Environment

A Linux-based development environment for Sharp X68000 software development, featuring automated build, test, and validation workflows.

## Overview

This repository provides everything needed to develop software for the Sharp X68000 vintage Japanese home computer:

- **VASM assembler** - vasmm68k_mot for Motorola 68000 assembly
- **GCC C toolchain** - m68k-linux-gnu-gcc with a full GCC → ELF → raw binary → `.X` pipeline
- **MAME emulation** - Test programs with the MAME X68000 emulator
- **Automated build system** - Makefile-based workflow
- **Automated testing** - Lua-based MAME validation with screenshot capture
- **Comprehensive documentation** - Beginner-friendly guides

## Quick Start

### Prerequisites

- Ubuntu 22.04 or later (or compatible Linux)
- 2GB free disk space
- X68000 BIOS ROMs (must be obtained legally)
- `xdotool` for automated warning dismissal (`sudo apt install xdotool`)

### Installation

```bash
# Clone the repository
git clone <repository-url> x68000dev
cd x68000dev

# Install dependencies
sudo apt install -y mame mtools xdotool gcc-m68k-linux-gnu binutils-m68k-linux-gnu

# Verify X68000 ROMs are installed
mame -verifyroms x68000

# Build all example programs
make all
```

### Test Your Setup

```bash
# Interactive: boot MAME with the development disk (manual use)
make test

# Automated: build, run, validate, and exit (CI-friendly)
make test-auto
```

`make test` opens a MAME window. The warning screen is dismissed automatically;
the X68000 boots to the `A>` prompt where `AUTOEXEC.BAT` runs the program.

`make test-auto` runs the same flow fully unattended and exits with a pass/fail
result code suitable for CI pipelines.

## Features

### ✅ Assembly Build System

- **One-command builds** - `make all` builds both example programs to Human68k `.X` executables
- **VASM assembler** - vasmm68k_mot with `-Fxfile` output for the assembly hello world
- **GCC C pipeline** - `src/hello_c.c` compiled via GCC → ELF → `objcopy` → `make_xfile.py` header wrap
- **Auto-install** - `make install` copies both binaries to the boot disk via mtools
- **Automatic dependency tracking** - rebuilds when source changes

### ✅ MAME Emulation Integration

- **Automated warning dismissal** - cfg pre-patch sets `warned` to a far-future
  value before every launch so MAME never shows the imperfect-emulation warning;
  a XTEST mouse click provides a fallback in case the cfg is not read
- **`-nomouse` flag** - prevents host mouse coordinates from reaching the X68000
  analog mouse ports (eliminates spurious input after program exits)
- **Boot disk support** - programs auto-install to the floppy image via mtools
- **Lua scripting** - real-time TVRAM/GVRAM validation with screenshot capture

### ✅ Automated Testing

- **`test_hello.lua`** - waits 70 real seconds for boot + execution, then validates
  output by sampling the full 32 KB text VRAM plane (stride-4 scan handles
  hardware scroll — visible text can be anywhere in `0xE00000`–`0xE07FFF`)
- **Both programs validated** - `AUTOEXEC.BAT` runs `HELLOA.X` then `HELLO_C.X`
  sequentially; a single TVRAM hit from either program is sufficient to pass
- **Pass/fail exit codes** - `TEST PASSED` / `TEST PARTIAL` / `TEST FAILED`
- **Screenshot on every run** - saves `hello_result.png` via MAME's screen capture
- **150-second watchdog** - kills MAME if the warning screen was not dismissed

### ✅ Beginner-Friendly Documentation

- **[Setup Guide](docs/SETUP.md)** - Complete installation instructions
- **[Build Guide](docs/BUILD.md)** - Understanding the build system
- **[Testing Guide](docs/TESTING.md)** - MAME testing workflows
- **[Debugging Guide](docs/DEBUGGING.md)** - GDB debugging techniques
- **[X68000 Guide](docs/X68000_GUIDE.md)** - X68000 programming primer

## Directory Structure

```
x68000dev/
├── src/                    # Source code
│   ├── helloa.s             # Assembly hello world (VASM, F-line DOS calls)
│   ├── helloc.c           # C hello world (GCC, inline asm F-line DOS calls)
│   └── crt0.s              # Minimal C runtime startup (GAS, calls main then _EXIT)
├── include/                # Header files
├── build/                  # Build output (gitignored)
│   ├── bin/                # Final executables
│   │   ├── helloa.x       # Assembly hello world (.X executable)
│   │   ├── helloc.x       # C hello world (.X executable)
│   │   ├── helloc.elf     # Intermediate ELF (for inspection/debugging)
│   │   └── helloc.bin     # Intermediate raw binary (before .X header)
│   └── obj/                # Object files
│       ├── crt0.o
│       └── helloc.o
├── mame/                   # MAME configuration and Lua scripts
│   ├── mame.ini            # MAME settings
│   ├── test_hello.lua      # Automated validation script
│   ├── test_comprehensive.lua  # Extended memory analysis script
│   └── debug_session.gdb   # GDB debugging script
├── tests/                  # Test support files
│   └── autoexec_test.bat   # AUTOEXEC.BAT installed during test-auto
│                           # runs HELLOA.X then HELLO_C.X sequentially
├── tools/                  # Build and utility scripts
│   ├── vasmm68k_mot        # VASM M68k assembler binary
│   ├── make_xfile.py       # Wraps a raw binary in a Human68k .X header
│   ├── test.sh             # Interactive MAME launcher
│   └── test_gui_automated.sh  # Fully automated test runner
├── docs/                   # Documentation
├── Makefile                # Main build file
├── x68k.ld                 # Linker script (entry _start, origin 0x6800)
├── MasterDisk_V3.xdf       # X68000 boot disk image
└── README.md               # This file
```

## Usage

### Build Commands

```bash
# Assemble and link
make all

# Install binary to boot disk
make install

# Interactive MAME session
make test

# Fully automated test (CI-friendly)
make test-auto

# Clean build artifacts
make clean
```

### How the Automated Test Works

1. `test_gui_automated.sh` backs up `AUTOEXEC.BAT` and installs a test version
   (`tests/autoexec_test.bat`) that auto-runs `HELLOA.X` then `HELLO_C.X` on boot
2. Both `HELLOA.X` and `HELLO_C.X` are copied to the boot disk via mtools
3. `~/.mame/cfg/x68000.cfg` is patched to set `warned="9999999999"` so MAME skips
   the imperfect-emulation warning on startup. MAME resets `warned` to the current
   timestamp at session exit, so this patch runs before every launch.
4. MAME launches with `-nomouse` (prevents host mouse from reaching the X68000
   mouse port) and `-script mame/test_hello.lua`
5. As a fallback, `xdotool` moves the cursor to the MAME window centre and sends
   a XTEST mouse click (no `--window` flag, so SDL2 treats it as real hardware
   input rather than filtering it as a synthetic XSendEvent)
6. After 70 real seconds the Lua script samples the full 32 KB text VRAM plane
   (stride-4, covers any CRTC hardware-scroll offset), saves a screenshot, prints
   `TEST PASSED` / `TEST PARTIAL` / `TEST FAILED`, and exits MAME
7. The original `AUTOEXEC.BAT` is restored

## Example Programs

### Assembly hello world (`src/hello.s`)

Built directly with VASM to a native `.X` file:

```asm
    section text
start:
    pea     msg(pc)
    dc.w    $ff09       * DOS _PRINT (F-line dispatch)
    addq.l  #4,sp
    dc.w    $ff00       * DOS _EXIT

    section data
msg:
    dc.b    'Hello from X68000!',13,10,0
    end start
```

### C hello world (`src/hello_c.c` + `src/crt0.s`)

Built through GCC → ELF → raw binary → `.X` header wrap:

```c
static void dos_print(const char *msg) {
    __asm__ __volatile__(
        "pea (%0)\n\t"       /* push string address */
        ".word 0xff09\n\t"   /* DOS _PRINT */
        "addq.l #4, %%sp"    /* pop argument */
        : : "a" (msg) : "memory"
    );
}

void main(void) {
    dos_print("Hello from C on X68000!\r\n");
}
```

**Build pipeline:**
```
src/hello_c.c  ──[gcc -m68000 -mpcrel]──► build/obj/hello_c.o ─┐
src/crt0.s     ──[as  -m68000]──────────► build/obj/crt0.o     ─┤
                                                                  └─[ld -T x68k.ld]──► hello_c.elf
                                                                                           │
                                                                              [objcopy -O binary]
                                                                                           │
                                                                              hello_c.bin
                                                                                           │
                                                                      [make_xfile.py (64-byte .X header)]
                                                                                           │
                                                                              hello_c.x
```

The `-mpcrel` flag is critical: it makes GCC emit PC-relative data references
(`pea (offset,PC)` instead of `pea $absolute`). Without it the binary only runs
if loaded at exactly the linker origin address; with it the binary is
position-independent and runs wherever Human68k places it in memory.

Key points for both programs:
- Human68k DOS calls use **F-line opcodes** (`dc.w $FFxx`), not `TRAP #15` (IOCS/hardware BIOS)
- `$FF09` = `_PRINT` — prints a null-terminated string whose address is on the stack
- `$FF00` = `_EXIT` — terminates the process and returns to `COMMAND.X`

## Technical Details

### Toolchain

- **Assembly path:** vasmm68k_mot (VASM, Motorola syntax) → native `.X` via `-Fxfile`
- **C path:** m68k-linux-gnu-gcc → ELF → objcopy (raw binary) → `make_xfile.py` (`.X` header)
- **Target CPU:** Motorola 68000 (`-m68000`)
- **Emulator:** MAME
- **OS:** Human68k (X68000 operating system)

### Build Process

**Assembly program (`helloa.x`):**
1. **Assemble** `src/hello.s` with VASM (`-Fxfile -nosym`)
2. **Output** `build/bin/helloa.x` — a ready-to-run Human68k `.X` executable

**C program (`hello_c.x`):**
1. **Compile** `src/hello_c.c` with GCC (`-m68000 -nostdlib -ffreestanding -mpcrel`)
2. **Assemble** `src/crt0.s` with GAS (`-m68000`) — provides the `_start` entry point
3. **Link** with `m68k-linux-gnu-ld -T x68k.ld` → `build/bin/hello_c.elf`
4. **Extract** raw binary with `objcopy -O binary` → `build/bin/hello_c.bin`
5. **Wrap** with `tools/make_xfile.py` — prepends the 64-byte `.X` header → `build/bin/hello_c.x`

### Memory Layout

- **Program load address:** 0x6800 (Human68k standard)
- **Text VRAM (TVRAM):** 0xE00000
- **Graphics VRAM (GVRAM):** 0xC00000
- **I/O registers:** 0xE80000 – 0xEB0000

### MAME Warning Dismissal

MAME shows an "imperfect emulation" warning before booting the X68000. Two
mechanisms work in tandem to suppress it:

1. **Config pre-acknowledgement** — sets `warned="9999999999"` in
   `~/.mame/cfg/x68000.cfg` before every launch. MAME compares `warned` against
   the current launch timestamp; because `9999999999` (year 2286) is always
   greater, no warning is shown. MAME resets `warned` to the real dismissal time
   at session exit, so the patch must run on every invocation.
2. **XTEST mouse click fallback** — `xdotool` moves the cursor to the window
   centre and clicks without the `--window` flag. Omitting `--window` causes
   xdotool to use `XTestFakeButtonEvent` (XTEST) instead of `XSendEvent`; SDL2
   accepts XTEST events as real hardware input and silently discards XSendEvent.

`-nomouse` is passed to MAME so the host mouse coordinates injected by
`xdotool` do not reach the X68000 analog mouse hardware (which would otherwise
appear as continuous input in Human68k after the program exits).

## Resources

### Documentation

- [Setup Guide](docs/SETUP.md) - First-time setup
- [Build System Guide](docs/BUILD.md) - Build process details
- [Testing Guide](docs/TESTING.md) - MAME testing
- [Debugging Guide](docs/DEBUGGING.md) - GDB debugging
- [X68000 Programming Guide](docs/X68000_GUIDE.md) - Learn X68000 programming

### External Resources

- [MAME Documentation](https://docs.mamedev.org/)
- [X68000 Technical Information](https://en.wikipedia.org/wiki/X68000)
- [Motorola 68000 Programmer's Reference](https://www.nxp.com/docs/en/reference-manual/M68000PRM.pdf)
- X68000 development communities (forums, Discord)

## License

This development environment is provided as-is for educational purposes.

**Note:** X68000 BIOS ROM files are required but not included. You must obtain
these legally (dump from your own hardware or through legal channels). BIOS ROMs
are copyrighted by Sharp Corporation.

## Credits

- Sharp Corporation — X68000 hardware and software
- MAME Development Team — Emulator
- VASM Development Team — Assembler
- X68000 community — Documentation and support
