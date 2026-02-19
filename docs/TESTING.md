# X68000 Testing Guide

This guide explains how to test your X68000 programs using the MAME emulator.

## Quick Start

```bash
# Build and test in one command
make test

# Or use the test script directly
./tools/test.sh
```

## Testing Workflow

### 1. Build the Program

```bash
make all
```

This compiles your code and installs it to the boot disk.

### 2. Run MAME

```bash
./tools/test.sh
```

MAME will launch with the boot disk loaded. The imperfect-emulation warning is
suppressed automatically — no manual dismissal is needed.

### 3. Execute the Program

When you see the Human68k prompt (`A>`):

1. Type: `A:HELLOA.X`
2. Press Enter

Your program will execute.

### 4. Exit MAME

Press **Ctrl+C** in the terminal where you launched MAME.

## MAME Emulator

### What is MAME?

MAME (Multiple Arcade Machine Emulator) is a highly accurate emulator that supports the Sharp X68000 and hundreds of other systems.

### Why MAME for X68000 Development?

- **Accurate emulation** - Very close to real hardware
- **Command-line control** - Perfect for automation
- **Debugging support** - GDB integration
- **Lua scripting** - Advanced automation
- **Cross-platform** - Linux, Windows, macOS
- **Free and open source**

### MAME X68000 Features

- Cycle-accurate 68000 CPU emulation
- Graphics hardware emulation (GVRAM, text, sprites)
- Sound emulation (ADPCM, OPM, etc.)
- Floppy disk support
- Hard disk support
- MIDI support
- Mouse and joystick support

## Manual MAME Usage

### Basic Launch

```bash
mame x68000 -flop1 MasterDisk_V3.xdf -window
```

**Flags:**
- `x68000` - System to emulate
- `-flop1` - Floppy disk in drive 1
- `-window` - Run in window mode (not fullscreen)

### Useful MAME Options

```bash
# Windowed mode with specific resolution
mame x68000 -flop1 MasterDisk_V3.xdf -window -resolution 768x512

# Disable maximize
mame x68000 -flop1 MasterDisk_V3.xdf -window -nomax

# Skip startup info screens
mame x68000 -flop1 MasterDisk_V3.xdf -skip_gameinfo

# Run for specific time then exit (headless testing)
mame x68000 -flop1 MasterDisk_V3.xdf -video none -sound none -seconds_to_run 30
```

### MAME Keyboard Shortcuts

While MAME is running:

- **Tab** - Open MAME menu
- **F3** - Reset emulation
- **F12** - Take screenshot
- **P** - Pause
- **Shift+P** - Turbo mode (fast forward)
- **F10** - Throttle toggle
- **Scroll Lock** - Enable/disable MAME UI keys

## Automated Testing

### Using Lua Scripts

MAME supports Lua scripting for automation. Our `mame/autoboot.lua` script provides basic automation:

```bash
mame x68000 \
    -flop1 MasterDisk_V3.xdf \
    -window \
    -script mame/autoboot.lua
```

**Note:** Full keyboard automation in MAME Lua requires version-specific API usage and can be complex. The provided script demonstrates the basic structure.

### Headless Testing

For CI/CD pipelines, you can run MAME without a display:

```bash
mame x68000 \
    -flop1 MasterDisk_V3.xdf \
    -video none \
    -sound none \
    -seconds_to_run 30
```

This runs the emulator for 30 seconds then exits automatically.

### Screenshot Capture

Take screenshots during testing:

```bash
mame x68000 \
    -flop1 MasterDisk_V3.xdf \
    -window \
    -snapname screenshot \
    -seconds_to_run 20
```

Press **F12** during execution, or use Lua scripting to capture automatically.

Screenshots are saved to the `snap/` directory.

## Verifying Boot Disk Contents

Check what's on the boot disk:

```bash
mdir -i MasterDisk_V3.xdf ::
```

This lists all files in the root directory.

Copy a file from the disk:

```bash
mcopy -i MasterDisk_V3.xdf ::HELLOA.X ./helloa.x
```

Delete a file from the disk:

```bash
mdel -i MasterDisk_V3.xdf ::HELLOA.X
```

## Testing Best Practices

### 1. Test Early and Often

Build and test frequently during development:

```bash
# Quick iteration
make clean && make all && make test
```

### 2. Visual Verification

For graphics programs:
- Check colors are correct
- Verify positioning
- Test animations
- Look for graphical glitches

### 3. Manual Testing

Automated testing has limitations. Some things require manual verification:
- Visual quality
- Sound output
- Input responsiveness
- Edge cases

### 4. Save States

MAME supports save states. Use them to quickly return to specific points:

1. **F7** - Save state
2. **F8** - Load state
3. **Shift+F7** - Save to specific slot

This helps test specific scenarios without repeating setup steps.

### 5. Test on Real Hardware (If Available)

MAME is very accurate but not perfect. If you have access to real X68000 hardware:
- Test timing-critical code
- Verify sound output
- Check hardware edge cases
- Validate final builds

## Common Issues

### Program Doesn't Start

- Verify it's installed: `mdir -i MasterDisk_V3.xdf ::`
- Check file size is non-zero: `ls -lh build/bin/helloa.x`
- Try rebuilding: `make clean && make all`

### Graphics Don't Appear

- Check graphics initialization code
- Verify GVRAM addresses (0xC00000)
- Ensure supervisor mode is enabled
- Check graphics mode settings

### MAME Crashes or Hangs

- Verify ROMs: `mame -verifyroms x68000`
- Update MAME: `sudo apt update && sudo apt upgrade mame`
- Check system resources (RAM, CPU)
- Try different MAME versions

### "Illegal Instruction" in X68000 Code

- Check assembly syntax
- Verify instruction is valid for 68000 (not 68020/68030)
- Review linker script entry point
- Check for uninitialized function pointers

## Advanced Testing

### Performance Testing

Use MAME's built-in profiling:

```bash
mame x68000 -flop1 MasterDisk_V3.xdf -window -profiling
```

This generates performance data.

### Regression Testing

Keep reference screenshots of working builds:

```bash
mkdir -p tests/screenshots/reference
# Take screenshot of known good build
# Compare with new builds
```

Use image comparison tools to detect visual regressions.

## Next Steps

- Read [DEBUGGING.md](DEBUGGING.md) - Learn about debugging
- Read [X68000_GUIDE.md](X68000_GUIDE.md) - Learn X68000 programming
- Read [GRAPHICS_API.md](GRAPHICS_API.md) - Graphics programming reference
