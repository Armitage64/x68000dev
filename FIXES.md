# Out Run Music Player - Critical Bug Fixes

## Summary
Fixed major bugs in the C version (`outrun.c`) that were causing the program to fail. The main issue was using the wrong trap number for MXDRV calls.

## Critical Fixes

### 1. **WRONG TRAP NUMBER** (Most Important!)
**Problem:** Code was using `trap #2` for MXDRV calls
**Fix:** Changed to `trap #10` - this is the correct trap for MXDRV
**Impact:** This was causing error $d022 and complete failure

**Before:**
```c
__asm__ volatile (
    "move.w %1,%%d0\n\t"
    "trap #2\n\t"     // WRONG!
    ...
```

**After:**
```c
__asm__ volatile (
    "move.w %1,-(%%sp)\n\t"
    "trap #10\n\t"    // CORRECT!
    ...
```

### 2. **Wrong Parameter Passing Convention**
**Problem:** Parameters were passed in registers (d0)
**Fix:** Parameters must be pushed on stack before trap #10
**Impact:** Even with correct trap, wrong calling convention would fail

**MXDRV Functions:**
- Simple calls: Push function number (2 bytes), trap #10, clean up 2 bytes
- MXDRV_PLAY: Push data pointer (4 bytes), push function number (2 bytes), trap #10, clean up 6 bytes

### 3. **Using MXDRV_START Instead of MXDRV_STAT**
**Problem:** Trying to initialize MXDRV with START command
**Fix:** Use STAT to check if MXDRV is already loaded (loaded externally as TSR)
**Impact:** Prevents conflicts with pre-loaded MXDRV.X

### 4. **Calling MXDRV_END on Exit**
**Problem:** Code was calling MXDRV_END to unload MXDRV
**Fix:** Don't call MXDRV_END since we didn't load MXDRV (user loaded it as TSR)
**Impact:** Prevents unloading MXDRV for other programs

## How to Test

1. Make sure MXDRV.X is loaded as TSR:
   ```
   MXDRV.X
   ```

2. Compile the fixed C version (when toolchain is ready):
   ```
   m68k-human68k-gcc -m68000 -O2 -Wall -o outrunc.elf outrun.c -ldos -liocs
   m68k-human68k-objcopy -O xfile outrunc.elf outrunc.x
   ```

3. Run in MAME or real hardware:
   ```
   outrunc.x
   ```

## Technical Details

### MXDRV Calling Convention (trap #10)
All MXDRV functions use trap #10 with parameters on stack:

| Function | Stack Layout (top to bottom) | Cleanup |
|----------|------------------------------|---------|
| STAT/STOP/etc | func# (word) | 2 bytes |
| PLAY | func# (word), ptr (long) | 6 bytes |

### DOS Calls (trap #15)
DOS calls use trap #15:
- _INKEY ($01): Read keyboard input
- _PRINT, _OPEN, _READ, etc.

## Comparison with Assembly Version

The assembly version (`outrun.s`) uses the same calling convention:
```asm
; Example MXDRV call
move.w  #MXDRV_STOP,-(sp)   ; Push function number
trap    #10                  ; MXDRV trap
addq.l  #2,sp               ; Clean up stack
```

## Files Modified
- `outrun.c` - Fixed all MXDRV and DOS calling conventions

## Commits
1. "Fix MXDRV calling convention - use trap #10 not trap #2"
2. "Don't call MXDRV_END on exit - MXDRV.X loaded externally"
