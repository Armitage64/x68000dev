# Manual Test Instructions

## Current Status

- ✅ Build system working
- ✅ Program built (68 bytes)
- ✅ Installed to boot disk as PROGRAM.X
- ✅ Test script updated with validation
- ⚠️ Xvfb doesn't provide proper environment for X68000 boot
- 🎯 Need manual test with real display

## How to Test

### Option 1: Fully Automated (Requires Manual Run)

```bash
make test
```

**What will happen:**
1. MAME window opens
2. X68000 boots to Human68k prompt (wait ~30 seconds)
3. **Manually type: `A:PROGRAM.X` and press Enter**
4. Wait 10 seconds
5. Lua script checks VRAM and prints results in terminal
6. MAME auto-closes after 50 seconds

**Expected results in terminal:**
- If working: `[LUA] ✓ GVRAM activity detected`
- If failing: `[LUA] ✗ GVRAM activity: 0 non-zero locations`

### Option 2: Check Boot Disk Contents

```bash
mdir -i MasterDisk_V3.xdf ::
```

Should show:
```
PROGRAM  X          68 [current date/time]
```

### Option 3: Try Auto-Execution

Install AUTOEXEC.BAT that auto-runs the program:

```bash
# Install auto-run AUTOEXEC.BAT
mcopy -i MasterDisk_V3.xdf -o tests/autoexec_test.bat ::AUTOEXEC.BAT

# Run test
make test

# System should auto-run PROGRAM.X after boot
# Lua script validates after 40 seconds
```

**Then restore original:**
```bash
# Restore original AUTOEXEC.BAT from backup if needed
```

## What to Look For

### If "can not run the file" error appears:

This means:
- ✅ Human68k booted successfully
- ✅ AUTOEXEC.BAT (or manual command) ran
- ❌ Our .X file format is incorrect

**Solution:** We need to fix the Human68k executable format.

### If program runs but crashes silently:

- ✅ File format correct
- ❌ Code has a bug (possibly trying to access GVRAM without permission)

**Solution:** May need to enter supervisor mode or use IOCS calls.

### If VRAM validation passes:

🎉 **SUCCESS!** Everything works and automated testing is complete!

## Diagnostic Commands

### Check what's on the boot disk:
```bash
mdir -i MasterDisk_V3.xdf ::
```

### Examine our program:
```bash
hexdump -C build/bin/program.x | head -10
ls -lh build/bin/program.x
```

### Check Text VRAM contains boot messages (if MAME is running):

The Lua script will report this automatically after 40 seconds.

## Next Steps After Manual Test

Please run `make test` and report back:

1. **Does Human68k boot to the prompt?** (Should take ~30 seconds)
2. **Can you type `A:PROGRAM.X` and press Enter?**
3. **What happens?**
   - "can not run the file" error?
   - Program runs but nothing visible?
   - Program runs and you see graphics?
   - System crashes?
4. **What does the Lua script report in the terminal?**
   - GVRAM activity detected?
   - No activity?

Based on your results, I can then:
- Fix the .X file format if needed
- Fix the code if it's executing but not drawing
- Celebrate if it works! 🎉

## Current Program

Our current `program.x` (68 bytes):
- Simple startup code with BRA header
- Fills GVRAM with pattern (no supervisor mode or graphics setup)
- Very minimal to test if basic execution works

If this format fails, I'll create a proper Human68k .X header.
