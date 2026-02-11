# Out Run Music Player for Sharp X68000

A simple music player that plays the four iconic music tracks from the arcade game Out Run on the Sharp X68000 computer using the MXDRV music driver.

**Available in two versions:**
- **Assembly version** (`outrun.s` → `outrun.x`) - Original M68000 assembly implementation
- **C version** (`outrun.c` → `outrunc.x`) - Rewritten in C for easier maintenance and portability

## Features

- Play four Out Run music tracks:
  - Magical Sound Shower
  - Passing Breeze
  - Splash Wave
  - Last Wave
- Simple text-based menu interface
- Stop/resume playback
- Clean exit handling

## Files

### Source Code
- `outrun.s` - Assembly source code
- `outrun.c` - C source code
- `build.bat` - Windows build script (assembly)
- `build.sh` - Linux/Mac build script (assembly)
- `build_c.bat` - Windows build script (C version)
- `build_c.sh` - Linux/Mac build script (C version)
- `Makefile` - Build system for both versions

### Music Data
- `MAGICAL.MDX` - Magical Sound Shower music data
- `PASSING.MDX` - Passing Breeze music data
- `SPLASH.MDX` - Splash Wave music data
- `LAST.MDX` - Last Wave music data

### Runtime
- `mxdrv.x` - MXDRV music driver

## Requirements

### Development Tools

**For Assembly Version:**
- **VASM** - Motorola 68000 assembler
  - Windows: Included in vbcc package
  - Linux/Mac: Download from http://sun.hasenbraten.de/vasm/

**For C Version:**
- **gcc-4.6.2-human68k** - Human68k cross-compiler
  - Source: https://github.com/Lydux/gcc-4.6.2-human68k
  - Also requires: binutils-2.22-human68k, newlib-1.19.0-human68k
  - The C version uses standard C library functions which properly handle Human68k DOS I/O

**For Testing:**
- **MAME** - Multi Arcade Machine Emulator
  - Download from https://www.mamedev.org/

### Installation Locations (as configured)

- VASM: `C:\dev\vbcc\bin\vasmm68k_mot.exe` (Windows)
- GCC: `human68k-gcc` (should be in PATH)
- MAME: `C:\dev\mame\mame.exe` (Windows)

If your tools are installed elsewhere, edit the paths in the build scripts.

## Building

### Assembly Version

**Windows:**
```batch
build.bat
```

**Linux/Mac:**
```bash
chmod +x build.sh
./build.sh
```

This will create `outrun.x` - the executable program.

### C Version

**Windows:**
```batch
build_c.bat
```

**Linux/Mac:**
```bash
chmod +x build_c.sh
./build_c.sh
```

**Manual (Windows):**
```batch
human68k-gcc.exe -m68000 -O2 -Wall -o outrunc.elf outrun.c -ldos -liocs
human68k-objcopy.exe -O xfile outrunc.elf outrunc.x
del outrunc.elf
```

This will create `outrunc.x` - the C version executable.

### Using Makefile

You can also use the Makefile to build both versions:

```bash
make         # Build both versions
make asm     # Build assembly version only
make c       # Build C version only
make clean   # Clean build files
make help    # Show help
```

### Which Version Should I Use?

**Assembly version (`outrun.x`):**
- Smaller executable size (~2KB)
- Direct hardware/DOS interface
- Useful for learning M68000 assembly

**C version (`outrunc.x`):**
- More maintainable code
- Better I/O handling through standard C library
- Recommended for actual use and further development
- Uses proper buffered I/O which should display output correctly

## Running

### In MAME (Recommended for Testing)

**Windows:**
```batch
C:\dev\mame\mame.exe x68000 -ramsize 4M -flop1 outrun.x
```

**Linux/Mac:**
```bash
mame x68000 -ramsize 4M -flop1 outrun.x
```

### On Real Hardware

1. Copy all files to a floppy disk or hard drive on your X68000
2. Make sure `MXDRV.X` and all `.MDX` files are in the same directory as `outrun.x`
3. Run `outrun.x` from Human68k

## Usage

When the program starts, you'll see a menu:

```
============================================
   OUT RUN Music Player for X68000
============================================

Select a track:
  1. Magical Sound Shower
  2. Passing Breeze
  3. Splash Wave
  4. Last Wave

  S. Stop music
  Q. Quit

Your choice:
```

Press the corresponding number key to play a track, `S` to stop the current music, or `Q` to quit the program.

## Technical Details

### System Requirements

- Sharp X68000 computer (or compatible emulator)
- Human68k operating system
- At least 256KB of RAM
- MXDRV music driver

### MXDRV

MXDRV is a popular music driver for the X68000 that supports the MDX music format. The driver handles all the low-level audio hardware programming, allowing this program to focus on user interface and file management.

### Memory Usage

**Assembly version:**
- Program code: ~2KB
- MXDRV driver: ~6KB
- Music data buffer: 64KB (allocated temporarily during file loading)

**C version:**
- Program code: ~15-20KB (includes C library functions)
- MXDRV driver: ~6KB
- Music data buffer: 64KB (allocated temporarily during file loading)

### Implementation Notes

The C version uses standard C library functions (`printf`, `getchar`, `fopen`, etc.) which properly interface with Human68k DOS calls through the C runtime. This provides better I/O handling compared to the raw assembly DOS calls in the assembly version.

Both versions use inline assembly to interface with the MXDRV music driver through trap #10 interrupts.

## Troubleshooting

### "Could not load MXDRV.X driver!"

Make sure `MXDRV.X` is in the same directory as the program.

### "Could not open MDX file!"

Ensure all four `.MDX` files are present in the same directory:
- `MAGICAL.MDX`
- `PASSING.MDX`
- `SPLASH.MDX`
- `LAST.MDX`

### No sound in MAME

Make sure you're using the X68000 system (`x68000`) and not another system. The X68000 has specific sound hardware (OKI MSM6258 ADPCM and Yamaha YM2151 FM) that MXDRV requires.

## License

This is a demonstration program created for educational purposes. The Out Run music tracks are copyright SEGA. MXDRV is copyright its respective authors (milk., K.MAEKAWA, Missy.M, Yatsube, RANN, Shalem).

## Future Enhancements

Possible additions for a future version:
- Volume control
- Fade out effects
- Display current playback position
- Playlist/queue system
- Support for additional music formats
- Graphical interface

---

Enjoy the music!
