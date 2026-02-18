# X68000 Development Environment

A Linux-based development environment for Sharp X68000 software development, featuring automated build, test, and validation workflows.

## Overview

This repository provides everything needed to develop software for the Sharp X68000 vintage Japanese home computer:

- **VASM assembler** - vasmm68k_mot for Motorola 68000 assembly
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
sudo apt install -y mame mtools xdotool

# Verify X68000 ROMs are installed
mame -verifyroms x68000

# Build the example program
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

- **One-command builds** - `make all` assembles and links to a Human68k `.X` executable
- **VASM assembler** - vasmm68k_mot with `-Fxfile` output format
- **Auto-install** - `make install` copies the binary to the boot disk via mtools
- **Automatic dependency tracking** - rebuilds when source changes

### ✅ MAME Emulation Integration

- **Automated warning dismissal** - dual mouse-move sequence reliably clears the
  MAME imperfect-emulation warning without requiring manual interaction
- **`-nomouse` flag** - prevents host mouse coordinates from reaching the X68000
  analog mouse ports (eliminates spurious input after program exits)
- **Boot disk support** - programs auto-install to the floppy image via mtools
- **Lua scripting** - real-time TVRAM/GVRAM validation with screenshot capture

### ✅ Automated Testing

- **`test_hello.lua`** - waits 70 real seconds for boot + execution, then scans
  TVRAM (0xE00000) and GVRAM (0xC00000) for output
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
├── src/                    # Assembly source code
│   └── hello.s             # Hello World (Human68k DOS calls via F-line)
├── include/                # Header files
├── assets/                 # Game resources
│   └── mdx/                # Music files (MDX format)
├── build/                  # Build output (gitignored)
│   └── bin/                # Final executables
│       └── program.x       # Human68k .X executable
├── mame/                   # MAME configuration and Lua scripts
│   ├── mame.ini            # MAME settings
│   ├── test_hello.lua      # Automated validation script
│   ├── test_comprehensive.lua  # Extended memory analysis script
│   └── debug_session.gdb   # GDB debugging script
├── tests/                  # Test support files
│   └── autoexec_test.bat   # AUTOEXEC.BAT installed during test-auto
├── tools/                  # Build and utility scripts
│   ├── vasmm68k_mot        # VASM M68k assembler binary
│   ├── test.sh             # Interactive MAME launcher
│   └── test_gui_automated.sh  # Fully automated test runner
├── docs/                   # Documentation
├── Makefile                # Main build file
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
   that auto-runs `PROGRAM.X` on boot
2. MAME's imperfect-emulation warning is pre-acknowledged in `~/.mame/cfg/x68000.cfg`
   by setting the `warned` timestamp to a far-future value
3. MAME launches with `-nomouse` (prevents host mouse from reaching the X68000
   mouse port) and `-script mame/test_hello.lua`
4. Two synthetic mouse moves (via `xdotool`) dismiss the warning screen reliably,
   regardless of where the host cursor was previously positioned
5. After 70 real seconds the Lua script checks TVRAM for text output, saves a
   screenshot, prints `TEST PASSED` / `TEST PARTIAL` / `TEST FAILED`, and exits MAME
6. The original `AUTOEXEC.BAT` is restored

## Example Program

`src/hello.s` is a minimal Human68k assembly program:

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

Key points:
- Human68k DOS calls use **F-line opcodes** (`dc.w $FFxx`), not `TRAP #15` (which is IOCS/hardware BIOS)
- `$FF09` = `_PRINT` — prints a null-terminated string whose address is on the stack
- `$FF00` = `_EXIT` — terminates the process and returns to `COMMAND.X`

## Technical Details

### Toolchain

- **Assembler:** vasmm68k_mot (VASM M68k Motorola syntax)
- **Output format:** `-Fxfile` — native Human68k `.X` executable
- **Target CPU:** Motorola 68000
- **Emulator:** MAME 0.242
- **OS:** Human68k (X68000 operating system)

### Build Process

1. **Assemble** `src/hello.s` with VASM (`-Fxfile -nosym`)
2. **Output** `build/bin/program.x` — a ready-to-run Human68k executable
3. **Install** to `MasterDisk_V3.xdf` with `mcopy` (mtools)

### Memory Layout

- **Program load address:** 0x6800 (Human68k standard)
- **Text VRAM (TVRAM):** 0xE00000
- **Graphics VRAM (GVRAM):** 0xC00000
- **I/O registers:** 0xE80000 – 0xEB0000

### MAME Warning Dismissal

MAME shows an "imperfect emulation" warning before booting the X68000. Two
mechanisms work in tandem to dismiss it:

1. **Config pre-acknowledgement** — sets `warned="9999999999"` in
   `~/.mame/cfg/x68000.cfg` so MAME believes it has already been shown
2. **Dual mouse move fallback** — `xdotool mousemove` sends two synthetic
   `MotionNotify` events to different window coordinates, guaranteeing a motion
   delta even if the host cursor is already at one of the target positions

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
