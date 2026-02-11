# X68000 Out Run Player - Build Notes

## Current Status

### What Works ✅
- Source code compiles successfully (both assembly and C)
- VASM and GCC toolchains work on Windows
- MXDRV.X loads and runs in XM6 emulator
- XM6 emulator runs commercial X68000 software

### What Doesn't Work ❌
- **Cross-compiled executables won't run in XM6**
- Both VASM-built and GCC-built .X files fail with "Can not run the file" or error $#11D0
- This affects ALL cross-compiled programs (outrun.x, hello.x, outrunc.x, mxtest.x)

## Root Cause

Cross-compilation toolchains (VASM + human68k-gcc + human68k-objcopy) produce executable files that are incompatible with XM6 emulator, despite using the correct `-Fxfile` and `-O xfile` formats.

## Recommended Solution

**Build using native X68000 development tools inside the emulator:**

### Steps:
1. Obtain HAS.X (Human68k Assembler) and HLK.X (linker) for X68000
   - Or get native GCC that runs ON X68000 (not cross-compiler)
2. Transfer source files to XM6 filesystem
3. Assemble/compile inside XM6 using native tools
4. Run the resulting .X files

This approach guarantees 100% compatible executables since they're built by native tools.

## Files in This Repository

### Assembly Version
- `outrun.s` - Main program in M68000 assembly
- `build.bat` / `build.sh` - Build scripts using VASM
- Output: `outrun.x` (1,262 bytes)

### C Version
- `outrun.c` - Rewritten in C for portability
- `mxdrv_asm.s` - MXDRV wrapper functions in assembly
- `buildc.bat` / `buildc.sh` - Build scripts using GCC
- Output: `outrunc.x` (~97 KB)

### Test Programs
- `hello.s` - Minimal hello world test
- `mxtest.c` - Minimal MXDRV test

### Music Files
- `LAST.MDX`, `MAGICAL.MDX`, `PASSING.MDX`, `SPLASH.MDX` - Out Run music tracks
- `MXDRV.X` - MXDRV music driver (must be loaded first)

## Build Instructions (When Fixed)

### Assembly Version (VASM - if toolchain fixed):
```batch
build.bat
```

### C Version (GCC - if toolchain fixed):
```batch
buildc.bat
```

### Usage:
1. Load MXDRV: `mxdrv`
2. Run player: `outrun.x` or `outrunc.x`
3. Select tracks 1-4, S to stop, Q to quit

## Changes Made During Development

1. ✅ Fixed filename underscore issues (outrun_c.x → outrunc.x)
2. ✅ Updated tool names for consistency
3. ✅ Created pure assembly MXDRV wrappers (avoiding inline asm issues)
4. ✅ Fixed Makefile format flags (-Fhunk → -Fxfile)
5. ✅ Added entry point directives (end start)
6. ✅ Modified to not try loading MXDRV (assume resident)
7. ✅ Created minimal test programs to isolate issues

## Next Steps

1. Research native X68000 development tools (HAS.X, HLK.X, or native GCC)
2. Set up build environment inside XM6 emulator
3. Rebuild using native tools
4. Test and verify executables run correctly

## Technical Details

### MXDRV Interface
- Uses trap #10 for all MXDRV functions
- Function codes: STAT=0x02, PLAY=0x03, STOP=0x04
- MXDRV must be loaded as TSR before running player

### Cross-Compilation Attempted
- VASM 1.9a with `-Fxfile` format
- human68k-gcc 4.8.0 with `-m68000`
- human68k-objcopy with `-O xfile`
- All produce files that XM6 rejects

### Error Observed
- Error code: $#11D0
- PC address varies per program
- Affects all cross-compiled executables equally
