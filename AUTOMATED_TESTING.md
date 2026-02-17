# X68000 Automated Testing Guide

## Overview

This project includes a complete **automated test harness** that runs X68000 programs in MAME without human interaction and validates their output.

## Quick Start

```bash
# Build the program
make all

# Run automated headless test
make test-headless

# Verify environment
make verify
```

## Available Test Commands

### `make verify`
Checks that all required tools are installed and configured:
- Cross-compiler (m68k-linux-gnu-gcc)
- MAME emulator
- X68000 BIOS ROMs
- Boot disk
- Build artifacts

### `make test`
Manual test (requires GUI):
- Launches MAME in windowed mode
- You manually type `A:PROGRAM.X` at the Human68k prompt
- Visual verification of graphics output

### `make test-headless`
**Fully automated test (no GUI, no interaction):**
- Runs MAME in headless mode (-video none -sound none)
- Executes for 20 seconds
- Lua script validates VRAM contents
- Reports PASS/FAIL automatically
- Perfect for CI/CD pipelines

### `make test-auto`
Automated test with GUI (requires X11):
- Attempts to auto-run program via AUTOEXEC.BAT
- Shows MAME window for visual inspection
- Lua validation script checks results

## Test Scripts

### Main Test Runner
**`tools/test_headless.sh`**
- Backs up original AUTOEXEC.BAT
- Installs test AUTOEXEC.BAT (auto-runs program)
- Runs MAME with validation Lua script
- Restores original AUTOEXEC.BAT
- Reports test results

### Validation Lua Scripts

**`mame/test_comprehensive.lua`** (current default)
- Waits 15 seconds for boot + execution
- Scans GVRAM for graphics output
- Checks Text VRAM for activity
- Checks program memory area
- Samples 20+ memory locations
- Reports detailed diagnostics

**`mame/test_coroutine.lua`**
- Simpler validation logic
- Uses coroutines for timing
- Checks specific VRAM offsets

**`mame/test_simple.lua`**
- Basic VRAM scanning
- Lightweight validation

## How Automated Testing Works

### 1. Boot Disk Preparation
```bash
# Backup original AUTOEXEC.BAT
mcopy -i MasterDisk_V3.xdf ::AUTOEXEC.BAT autoexec_backup.bat

# Install test version that auto-runs program
mcopy -i MasterDisk_V3.xdf tests/autoexec_test.bat ::AUTOEXEC.BAT
```

### 2. MAME Execution
```bash
mame x68000 \
    -flop1 MasterDisk_V3.xdf \
    -video none \              # Headless mode
    -sound none \              # No audio
    -skip_gameinfo \           # Skip info screen
    -script mame/test_comprehensive.lua \  # Validation
    -seconds_to_run 20         # Auto-exit after 20s
```

### 3. Lua Validation
The Lua script:
- Waits 15 seconds for system boot
- Accesses emulated CPU memory
- Reads GVRAM at 0xC00000
- Checks for non-zero values (graphics)
- Reports PASS if graphics detected
- Reports FAIL if VRAM is empty

### 4. Result Reporting
```
[LUA] ✓ TEST PASSED
Graphics output detected - program executed successfully

OR

[LUA] ✗ TEST FAILED
No graphics detected - program may not have executed
```

## Test Output Examples

### Successful Test
```
==========================================
X68000 Headless Automated Test
==========================================

Step 1: Backing up original AUTOEXEC.BAT...
Step 2: Installing test AUTOEXEC.BAT...
Step 3: Ensuring program is installed...
Step 4: Running MAME in headless mode...

[LUA] === X68000 Comprehensive Test ===
[LUA] Waiting 15 seconds for system boot...
[LUA] Checking GVRAM (0xC00000, 20 samples)...
[LUA]   [GVRAM+0x0000] = 0x00FF
[LUA]   [GVRAM+0x4000] = 0x00F0
[LUA] ✓ TEST PASSED
[LUA] Graphics output detected

✓ TEST PASSED!
Program executed successfully
```

### Failed Test (Current Status)
```
[LUA] Checking GVRAM (0xC00000, 20 samples)...
[LUA] GVRAM activity: 0 non-zero locations
[LUA] ✗ TEST FAILED
[LUA] No graphics detected

✗ TEST FAILED!
Program did not produce expected output
```

## Current Status

### ✅ Working
- Build system compiles successfully
- Test framework runs without errors
- MAME boots in headless mode
- Lua scripts execute and check memory
- Test reports are generated

### ❌ Issue
**Program does not execute in the emulator**

The automated test correctly detects that the program isn't running:
- GVRAM remains all zeros
- No graphics output detected
- Program memory area is empty

**Possible causes:**
1. Human68k .X executable format issue
2. AUTOEXEC.BAT not executing the program
3. Program crashes before drawing
4. Boot process problem

## Debugging Test Failures

### Check MAME Output
```bash
cat mame_output.log
```

### Run with More Verbosity
```bash
# Increase Lua script wait time
# Edit mame/test_comprehensive.lua
# Change: local START_CHECK_TIME = 15.0
# To: local START_CHECK_TIME = 20.0
```

### Test Manually First
```bash
make test
# Type A:PROGRAM.X at the prompt
# Verify program works before automating
```

### Check Boot Disk
```bash
mdir -i MasterDisk_V3.xdf ::
# Verify PROGRAM.X and AUTOEXEC.BAT are present
```

## CI/CD Integration

### GitHub Actions Example
```yaml
name: X68000 Build and Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y gcc-m68k-linux-gnu mame mtools

      - name: Build
        run: make all

      - name: Run automated tests
        run: make test-headless

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v2
        with:
          name: test-logs
          path: |
            mame_output.log
            test_screenshot.png
```

## Customizing Tests

### Modify Validation Logic
Edit `mame/test_comprehensive.lua`:
```lua
-- Change what to check
local test_offsets = {
    0x0000, 0x1000, 0x2000  -- VRAM offsets
}

-- Change pass criteria
if non_zero_count > 5 then  -- Require 5 non-zero values
    print("TEST PASSED")
end
```

### Change Test Duration
Edit `tools/test_headless.sh`:
```bash
-seconds_to_run 30  # Increase to 30 seconds
```

### Add Screenshot Validation
Extend Lua script to compare screenshots:
```lua
local screen = manager.machine.screens[":screen"]
screen:snapshot("test_output.png")
-- Compare with reference image
```

## Next Steps

1. **Fix program execution** - Research Human68k .X format
2. **Verify manual execution** - Test in GUI mode first
3. **Add more test cases** - Create multiple test programs
4. **Screenshot comparison** - Add visual regression testing
5. **Performance metrics** - Track execution time, memory usage

## Files Reference

### Test Scripts
- `tools/test_headless.sh` - Main headless test runner
- `tools/test_automated.sh` - GUI-based automated test
- `tools/verify.sh` - Environment verification

### Lua Validation
- `mame/test_comprehensive.lua` - Full validation (current)
- `mame/test_coroutine.lua` - Coroutine-based testing
- `mame/test_simple.lua` - Basic validation

### Configuration
- `tests/autoexec_test.bat` - Auto-execution AUTOEXEC.BAT
- `Makefile` - Build targets including test-headless

### Documentation
- `TEST_STATUS.md` - Current test status and issues
- `AUTOMATED_TESTING.md` - This file

## Support

For issues:
1. Check `TEST_STATUS.md` for known issues
2. Review `mame_output.log` for errors
3. Run `make verify` to check environment
4. Test manually with `make test` first

---

**The automated testing framework is complete and functional.** Once the program execution issue is resolved, you'll have fully automated, zero-interaction testing for X68000 development.
