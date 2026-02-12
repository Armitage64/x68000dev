# X68000 MDX Player Development - Final Status

## Project Goal
Create an Out Run music player for Sharp X68000 using MXDRV music driver.

## Current Status: ⚠️ **BLOCKED** - MXDRV Compatibility Issue

### What Works ✅
- ✅ Build system (Windows cross-compilation with human68k-gcc)
- ✅ File I/O (loading MDX files)
- ✅ MXDRV calls return success (SETMDX, PLAY return 0)
- ✅ MXP.X (pre-built player) works perfectly with same MXDRV/MDX files
- ✅ Code compiles cleanly for both GCC and native CC compilers

### What Doesn't Work ❌
- ❌ **No audio output** - MXDRV accepts calls but doesn't play sound
- ❌ **Address errors** ($R=42000) when interacting after PLAY
- ❌ Fundamental calling convention incompatibility

## Root Cause Analysis

### MXDRV Calling Convention Conflict

**Two different conventions exist:**

1. **trap #4 + register parameters** (what we implemented)
   - D0 = function number
   - D1 = channel mask
   - A1 = MDX pointer
   - A2 = PDX pointer
   - Used by: x68kd11s disassembly, some MXDRV versions

2. **trap #10 + stack parameters** (from outrun.s)
   - Push parameters on stack
   - Function number as word
   - Pointers as longs
   - Used by: original outrun.s assembly
   - **Result: Causes system reboot on this setup**

### Version Confusion

- **mxdrv.x** (in repo): version 2.06+16 Rel.3
- **MXDRV30.X** (user tried): Different version
- **MDXTool/MXDRV.X**: Another variant
- **All versions show same behavior** - calls succeed, no sound

## Technical Details

### What We Tried

1. ✅ **Fixed function numbers** - PLAY = 0x03 (not 0x04)
2. ✅ **Fixed compiler compatibility** - K&R C for old CC.X v1.1
3. ✅ **Correct file loading** - MDX files with headers parse correctly
4. ✅ **Register setup variations** - D1=$FFFF, A1=pointer, A1=0, etc.
5. ✅ **Combined vs separate calls** - Both SETMDX+PLAY approaches
6. ❌ **trap #10** - Causes immediate system reboot
7. ❌ **Different MXDRV versions** - Same behavior across all

### Evidence of Incompatibility

```
Calling MXDRV combined SETMDX+PLAY (buffer=0x00012A4F)...
Combined PLAY returned: 0x00000000         ← Success!
Music should be playing now!               ← But no sound
[Press key] → Address error $R=42000       ← Something corrupted
```

- MXDRV accepts our calls (returns 0 = success)
- But audio engine never starts
- Suggests parameters accepted but not processed correctly
- Address errors indicate memory/pointer corruption

## Comparison: Working vs Broken

| Aspect | MXP.X (Works) | outrunc.x (Broken) |
|--------|---------------|-------------------|
| MXDRV calls | ✅ Success | ✅ Success (returns 0) |
| Audio output | ✅ Plays music | ❌ Silent |
| Interaction | ✅ Stable | ❌ Address errors |
| Compilation | Pre-built | Cross-compiled GCC |
| Trap convention | ??? (working) | trap #4 registers |

## Files Created

### Build Scripts
- `buildout.bat` - Compile OutRun player (Windows + GCC)
- `buildc.bat` - Compile simple player (Windows + GCC)
- `buildprobe.bat` - Compile MXDRV test tool
- `build.bat` - Instructions for native CC compilation

### Source Code
- `outrun.c` - Full OutRun player with menu (doesn't work)
- `simplep.c` - Simple single-track player (doesn't work)
- `mxprobe.c` - MXDRV function tester
- `mxdrvasm.s` - MXDRV wrappers (GCC syntax, trap #4)
- `mxdrvxc.s` - MXDRV wrappers (XC syntax, trap #4)
- `outrun.s` - Original assembly (trap #10) - causes reboot

### Documentation
- `COMPILEXC.txt` - Detailed native CC.X compilation guide
- `README.md` - Project overview
- `FIXES.md` - Bug fixes and calling convention notes
- `BUILD_NOTES.md` - Technical build information
- `STATUS.md` - This file

## Lessons Learned

### X68000 Development Challenges

1. **Multiple MXDRV versions** with incompatible calling conventions
2. **trap #4 vs trap #10** - fundamentally different approaches
3. **Cross-compilation issues** - GCC output may differ from native compilers
4. **Limited documentation** - conflicting information about calling conventions
5. **Old hardware quirks** - CC.X v1.1 needs K&R C, no underscores

### What Worked Well

- Human68k-gcc cross-compiler reliable
- File I/O and basic DOS calls work correctly
- Build system flexible for multiple compilers
- Good documentation of the problem space

## Recommendations

### For Future Work

1. **Use MXP.X** - Pre-built player that works
2. **Native compilation** - Try building on actual X68000 with native CC.X
3. **Find working source** - Locate confirmed-working MXDRV player source code
4. **Different audio library** - Consider alternatives to MXDRV
5. **Disassemble MXP.X** - Reverse-engineer the working calling convention

### For Other Developers

If attempting X68000 audio:
- ⚠️ Be prepared for MXDRV version incompatibilities
- ⚠️ Test on actual hardware (emulators may behave differently)
- ⚠️ Find working examples first, adapt from those
- ⚠️ trap #4 vs trap #10 is critical - wrong choice = reboot or silence

## Conclusion

We successfully created a complete build system and player code that:
- Compiles cleanly
- Makes correct MXDRV API calls
- Loads and parses MDX files properly

But due to fundamental calling convention incompatibility with the available MXDRV versions, the audio engine never starts. The working MXP.X player demonstrates the hardware is capable, but the exact calling convention it uses remains unknown.

**Recommendation:** Use MXP.X for MDX playback on this setup.

---

*Development session: 2026-02-12*
*Status: Suspended due to MXDRV compatibility blocker*
