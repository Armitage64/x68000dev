# X68000 Development Environment Setup Guide

This guide will help you set up a complete X68000 development environment on Ubuntu Linux.

## Prerequisites

- Ubuntu 22.04 or later (or compatible Debian-based Linux)
- At least 2GB free disk space
- Internet connection for package downloads

## Step 1: Install Required Packages

```bash
sudo apt update
sudo apt install -y \
    build-essential \
    gcc-m68k-linux-gnu \
    binutils-m68k-linux-gnu \
    mame \
    mtools \
    dosfstools \
    gdb-multiarch \
    git \
    make
```

## Step 2: Verify Installation

Check that the tools are installed correctly:

```bash
# Check MAME
mame -version

# Check m68k cross-compiler
m68k-linux-gnu-gcc --version

# Check mtools
mcopy --version

# Check GDB
gdb-multiarch --version
```

## Step 3: Obtain X68000 BIOS ROM Files

**IMPORTANT:** MAME requires X68000 BIOS ROM files to emulate the system. These files are copyrighted by Sharp Corporation.

### Legal Options:

1. **Dump from your own X68000 hardware** (legal)
2. **Obtain from legal ROM distribution services** (check your local laws)

### Required Files:

You need the `x68000` ROM set, which includes files like:
- `cgrom.dat` - Character Generator ROM
- `iplrom.dat` - IPL ROM
- `scsiinrom.dat` - SCSI ROM
- And others...

### Installation:

1. Create the MAME ROM directory:
   ```bash
   mkdir -p ~/.mame/roms/x68000
   ```

2. Copy your legally obtained ROM files to `~/.mame/roms/x68000/`

3. Verify the ROMs:
   ```bash
   mame -verifyroms x68000
   ```

   You should see: `romset x68000 is good`

**Note:** We cannot provide ROM files. You must obtain them legally.

## Step 4: Clone This Repository

```bash
cd ~
git clone <repository-url> x68000dev
cd x68000dev
```

## Step 5: Verify Boot Disk

Check that the boot disk image is present:

```bash
ls -lh MasterDisk_V3.xdf
```

You should see a ~1.3MB file.

## Step 6: Test MAME with Boot Disk

```bash
mame x68000 -flop1 MasterDisk_V3.xdf -window
```

You should see the X68000 boot screen and eventually the Human68k prompt (A>).

Press **Ctrl+C** in the terminal to exit MAME.

## Step 7: Build the Example Program

```bash
make all
```

This will:
- Compile the example graphics program
- Create `build/bin/program.x`
- Install it to the boot disk

## Step 8: Test the Program

```bash
make test
```

Or manually:

```bash
./tools/test.sh
```

MAME will launch. When you see the `A>` prompt:
1. Type: `A:PROGRAM.X`
2. Press Enter
3. You should see three colored squares

## Troubleshooting

### "MAME can't find ROMs"

- Verify ROMs are in `~/.mame/roms/x68000/`
- Run `mame -verifyroms x68000` to check
- Ensure ROM files have correct names

### "Boot disk not found"

- Check `MasterDisk_V3.xdf` is in the repository root
- Verify file permissions: `chmod 644 MasterDisk_V3.xdf`

### "Cross-compiler not found"

- Reinstall: `sudo apt install gcc-m68k-linux-gnu`
- Check PATH: `which m68k-linux-gnu-gcc`

### "Permission denied" errors

- Ensure scripts are executable: `chmod +x tools/*.sh`
- Check file ownership: `ls -la`

## Next Steps

- Read [BUILD.md](BUILD.md) - Learn about the build system
- Read [TESTING.md](TESTING.md) - Learn about testing
- Read [X68000_GUIDE.md](X68000_GUIDE.md) - Learn X68000 programming

## Optional: Claude Code Integration

If you're using Claude Code, you can enable MCP servers for enhanced functionality:

Edit `~/.config/claude/config.json`:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/home/armitage/git/x68000dev"]
    }
  }
}
```

Restart Claude Code to load the MCP server.

## Summary

You should now have:
- ✅ MAME emulator installed
- ✅ m68k cross-compiler installed
- ✅ X68000 BIOS ROMs installed
- ✅ Boot disk ready
- ✅ Example program built and tested

You're ready to start developing for the X68000!
