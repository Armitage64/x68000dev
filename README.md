# X68000 Development Environment

A complete Linux-based development environment for Sharp X68000 software development, featuring automated build, test, and debug workflows.

## Overview

This repository provides everything needed to develop games and applications for the Sharp X68000 vintage Japanese home computer:

- **Cross-compilation toolchain** - m68k GCC compiler for Motorola 68000 CPU
- **MAME emulation** - Test your programs with the MAME X68000 emulator
- **Automated build system** - Makefile-based workflow
- **GDB debugging** - Source-level debugging with GDB and MAME
- **Comprehensive documentation** - Beginner-friendly guides
- **Example program** - Graphics test to verify your setup

## Quick Start

### Prerequisites

- Ubuntu 22.04 or later (or compatible Linux)
- 2GB free disk space
- X68000 BIOS ROMs (must be obtained legally)

### Installation

```bash
# Clone the repository
git clone <repository-url> x68000dev
cd x68000dev

# Install dependencies (already installed in this environment)
sudo apt install -y gcc-m68k-linux-gnu mame mtools gdb-multiarch

# Verify X68000 ROMs are installed
mame -verifyroms x68000

# Build the example program
make all
```

### Test Your Setup

```bash
# Run the test program in MAME
make test
```

When MAME boots to the `A>` prompt:
1. Type: `A:PROGRAM.X`
2. Press Enter
3. You should see three colored squares!

## Features

### ✅ Automated Build System

- **One-command builds** - `make all` compiles and installs to boot disk
- **Cross-compilation** - Uses m68k-linux-gnu-gcc for 68000 target
- **Custom linker script** - Proper Human68k .X executable format
- **Automatic dependency tracking** - Rebuilds when source changes

### ✅ MAME Emulation Integration

- **Command-line automation** - No GUI manipulation needed
- **Boot disk support** - Programs auto-install to floppy image
- **Lua scripting** - Extensible automation framework
- **Screenshot capture** - Document and test visual output

### ✅ Professional Debugging

- **GDB integration** - Industry-standard debugging tools
- **Source-level debugging** - Set breakpoints in C code
- **Memory inspection** - Examine VRAM, registers, RAM
- **Single-stepping** - Step through code line-by-line

### ✅ Beginner-Friendly Documentation

- **[Setup Guide](docs/SETUP.md)** - Complete installation instructions
- **[Build Guide](docs/BUILD.md)** - Understanding the build system
- **[Testing Guide](docs/TESTING.md)** - MAME testing workflows
- **[Debugging Guide](docs/DEBUGGING.md)** - GDB debugging techniques
- **[X68000 Guide](docs/X68000_GUIDE.md)** - X68000 programming primer
- **[Graphics API](docs/GRAPHICS_API.md)** - Graphics programming reference

## Directory Structure

```
x68000dev/
├── src/                    # Source code (C and assembly)
│   ├── main.c              # Example graphics program
│   └── start.s             # Human68k startup code
├── include/                # Header files
├── assets/                 # Game resources
│   └── mdx/                # Music files (MDX format)
├── build/                  # Build output (gitignored)
│   ├── obj/                # Object files
│   └── bin/                # Final executables
├── tools/                  # Build and utility scripts
│   ├── build.sh            # Build automation
│   ├── clean.sh            # Clean build artifacts
│   ├── install.sh          # Install to boot disk
│   ├── test.sh             # Run in MAME
│   └── debug.sh            # Launch GDB debugging
├── mame/                   # MAME configuration
│   ├── mame.ini            # MAME settings
│   ├── autoboot.lua        # Automation script
│   └── debug_session.gdb   # GDB debugging script
├── docs/                   # Documentation
│   ├── SETUP.md            # Setup guide
│   ├── BUILD.md            # Build system guide
│   ├── TESTING.md          # Testing guide
│   ├── DEBUGGING.md        # Debugging guide
│   ├── X68000_GUIDE.md     # X68000 programming primer
│   └── GRAPHICS_API.md     # Graphics API reference
├── Makefile                # Main build file
├── x68k.ld                 # Linker script
├── MasterDisk_V3.xdf       # X68000 boot disk image
└── README.md               # This file
```

## Usage

### Build Commands

```bash
# Build everything
make all

# Clean build artifacts
make clean

# Build and test
make test

# Just install to boot disk (no rebuild)
make install
```

### Utility Scripts

```bash
# Build the program
./tools/build.sh

# Clean build directory
./tools/clean.sh

# Install program to boot disk
./tools/install.sh

# Run in MAME emulator
./tools/test.sh

# Start GDB debugging session
./tools/debug.sh
```

### Debugging Workflow

**Terminal 1:** Start MAME with GDB stub

```bash
./tools/debug.sh
```

**Terminal 2:** Connect GDB

```bash
gdb-multiarch -x mame/debug_session.gdb
```

**GDB commands:**

```gdb
(gdb) break main          # Set breakpoint at main
(gdb) continue            # Run to breakpoint
(gdb) step                # Step through code
(gdb) print x             # Inspect variables
(gdb) x/16x 0xC00000      # Examine GVRAM
```

## Example Program

The included example program (`src/main.c`) demonstrates:

- Entering supervisor mode for hardware access
- Setting graphics mode (256 colors)
- Drawing colored rectangles to GVRAM
- Basic X68000 program structure

Modify this program to start your own X68000 projects!

## Development Workflow

1. **Edit code** in `src/` directory
2. **Build** with `make all`
3. **Test** with `make test`
4. **Debug** with `./tools/debug.sh` if needed
5. **Iterate** quickly with the automated workflow

## Technical Details

### Toolchain

- **Compiler:** gcc-m68k-linux-gnu (GCC 11.4.0)
- **Target:** Motorola 68000 CPU
- **Emulator:** MAME 0.242
- **OS:** Human68k (X68000 operating system)

### Build Process

1. **Compile** C source to object files (`.o`)
2. **Assemble** assembly source to object files
3. **Link** with custom linker script for Human68k format
4. **Convert** ELF to raw binary (`.X` executable)
5. **Install** to boot disk image using mtools

### Memory Layout

- **Program load address:** 0x6800 (Human68k standard)
- **Graphics VRAM:** 0xC00000
- **Text VRAM:** 0xE00000
- **I/O registers:** 0xE80000 - 0xEB0000

## Resources

### Documentation

- [Setup Guide](docs/SETUP.md) - First-time setup
- [Build System Guide](docs/BUILD.md) - Build process details
- [Testing Guide](docs/TESTING.md) - MAME testing
- [Debugging Guide](docs/DEBUGGING.md) - GDB debugging
- [X68000 Programming Guide](docs/X68000_GUIDE.md) - Learn X68000 programming
- [Graphics API Reference](docs/GRAPHICS_API.md) - Graphics programming

### External Resources

- [MAME Documentation](https://docs.mamedev.org/)
- [X68000 Technical Information](https://en.wikipedia.org/wiki/X68000)
- [Motorola 68000 Programmer's Reference](https://www.nxp.com/docs/en/reference-manual/M68000PRM.pdf)
- X68000 development communities (forums, Discord)

## Contributing

Contributions welcome! Areas for improvement:

- Enhanced MAME Lua automation
- More example programs
- Additional documentation
- Bug fixes and optimizations

## License

This development environment is provided as-is for educational purposes.

**Note:** X68000 BIOS ROM files are required but not included. You must obtain these legally (dump from your own hardware or through legal channels). BIOS ROMs are copyrighted by Sharp Corporation.

## Credits

- Sharp Corporation - X68000 hardware and software
- MAME Development Team - Emulator
- GNU Project - Cross-compilation toolchain
- X68000 community - Documentation and support

## Support

If you encounter issues:

1. Check the [Setup Guide](docs/SETUP.md) troubleshooting section
2. Verify your BIOS ROMs: `mame -verifyroms x68000`
3. Review documentation in `docs/`
4. Check MAME and toolchain versions

## Why Linux?

This Linux-based approach offers significant advantages over Windows:

- **Superior automation** - No GUI manipulation fragility
- **Professional debugging** - GDB integration with MAME
- **Simpler architecture** - Standard Unix tools
- **CI/CD ready** - Can run in GitHub Actions
- **Open source** - All tools are free
- **Command-line control** - Perfect for Claude automation

## Getting Started

New to X68000 development? Start here:

1. Read [docs/SETUP.md](docs/SETUP.md) to set up your environment
2. Read [docs/X68000_GUIDE.md](docs/X68000_GUIDE.md) to learn X68000 basics
3. Study the example program in `src/main.c`
4. Modify the example and rebuild with `make all`
5. Read [docs/GRAPHICS_API.md](docs/GRAPHICS_API.md) for graphics programming
6. Start building your own X68000 programs!

---

**Happy X68000 development! 🎮**
