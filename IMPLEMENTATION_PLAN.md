# X68000 Development Build/Test Environment Setup Plan

## Context

This plan establishes a complete Linux-based development environment for Sharp X68000 software development, enabling Claude to control compilation and automated testing. The X68000 is a vintage Japanese home computer using the Motorola 68000 CPU, requiring cross-compilation and emulator-based testing.

**Current State:**
- Ubuntu Linux with Claude Code installed
- Repository at `/home/armitage/git/x68000dev`
- Contains 4 OutRun MDX music files and mxdrv.x music driver
- MAME emulator already installed and tested ✓
- m68k cross-compiler already installed and tested ✓
- Boot floppy disk image available: `MasterDisk_V3.xdf`
- No existing build system in repository
- Target: Games/Graphics applications development

**Why This Change:**
The user needs an automated environment where Claude can compile X68000 programs using a cross-compiler and test them in the MAME emulator without manual intervention. This enables rapid iteration on game/graphics development with automated build-test cycles. Linux provides superior automation capabilities compared to Windows, with MAME offering command-line control, Lua scripting, and GDB debugging support.

---

## Implementation Approach

### 1. System Setup and Dependencies

**A. Verify Already-Installed Tools**

MAME and m68k cross-compiler are already installed and tested. Verify remaining tools:

```bash
# Verify MAME (already installed)
mame -version

# Verify cross-compiler (already installed)
m68k-linux-gnu-gcc --version

# Install additional tools if needed
sudo apt update
sudo apt install -y build-essential git make mtools dosfstools

# Optional: Node.js for MCP servers
sudo apt install -y nodejs npm

# Optional: GDB for debugging
sudo apt install -y gdb-multiarch
```

**B. Verify Boot Disk Image**

```bash
# Check that boot disk exists
ls -lh MasterDisk_V3.xdf

# Test that MAME can mount it
mame x68000 -flop1 MasterDisk_V3.xdf -window
```

**C. X68000 BIOS/ROM Files**

MAME requires X68000 BIOS ROM files to emulate the system. These must be obtained legally:

1. **Required ROM set:** `x68000` (CG, IPLROM, SCSIINROM, etc.)
2. **Installation location:** `~/.mame/roms/x68000/`
3. **Verification:** Run `mame -verifyroms x68000` to check if ROMs are valid

**Note:** ROM files are copyrighted. Users must dump from their own X68000 hardware or obtain legally. Claude cannot provide these files.

---

### 2. MCP Server Configuration

**Simple MCP Setup for Linux:**

Claude Code with the standard built-in tools (Bash, Read, Write, Edit, Grep, Glob) is sufficient for this workflow. The optional MCP servers below enhance functionality:

**A. Filesystem MCP Server** - Enhanced file access (optional)
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/home/armitage/git/x68000dev"
      ]
    }
  }
}
```

**B. Git MCP Server** - Enhanced git operations (optional)
```json
{
  "git": {
    "command": "npx",
    "args": [
      "-y",
      "@modelcontextprotocol/server-git",
      "--repository",
      "/home/armitage/git/x68000dev"
    ]
  }
}
```

**Note:** Unlike Windows, Linux doesn't require custom execution MCP servers. Claude can use the built-in Bash tool to run commands directly, making the setup much simpler and more reliable.

---

### 3. Directory Structure Reorganization

Transform flat repository into organized development environment:

```
/home/armitage/git/x68000dev/
├── src/                    # Source code (C and assembly)
│   ├── main.c
│   ├── start.s
│   ├── graphics/
│   └── utils/
├── include/                # Header files
│   └── *.h
├── assets/                 # Game resources
│   ├── mdx/                # Music (move existing MDX files here)
│   │   ├── MAGICAL.MDX
│   │   ├── SPLASH.MDX
│   │   ├── PASSING.MDX
│   │   └── LAST.MDX
│   ├── graphics/           # Sprites, tiles, backgrounds
│   └── data/               # Game data
├── build/                  # Build output (gitignored)
│   ├── obj/
│   └── bin/
├── tests/                  # Test programs
│   ├── test_graphics.c
│   └── test_config.json
├── tools/                  # Build and test utilities
│   ├── mxdrv.x             # Move existing music driver here
│   ├── install.sh          # Install program to boot disk
│   ├── build.sh            # Build script
│   ├── clean.sh            # Clean script
│   ├── test.sh             # Test automation script
│   └── debug.sh            # Debug with GDB script
├── mame/                   # MAME configuration and scripts
│   ├── mame.ini            # MAME configuration
│   ├── autoboot.lua        # Auto-boot Lua script
│   └── debug_session.gdb   # GDB debugging script
├── docs/                   # Documentation (beginner-friendly)
│   ├── SETUP.md            # Ubuntu setup guide
│   ├── BUILD.md            # Build system guide
│   ├── TESTING.md          # Test harness usage
│   ├── DEBUGGING.md        # GDB debugging guide
│   ├── X68000_GUIDE.md     # X68000 programming primer
│   └── GRAPHICS_API.md     # Graphics programming reference
├── Makefile                # Main build file
├── x68k.ld                 # Linker script
├── config.mk               # Build configuration
├── MasterDisk_V3.xdf       # X68000 boot disk image
├── .gitignore              # Ignore build artifacts
└── README.md               # Project overview
```

---

### 4. Build System Implementation

**A. Makefile** (`/home/armitage/git/x68000dev/Makefile`)

Core build automation using GCC m68k cross-compiler:

```makefile
# Toolchain (Ubuntu m68k cross-compiler)
CC = m68k-linux-gnu-gcc
AS = m68k-linux-gnu-as
LD = m68k-linux-gnu-ld
OBJCOPY = m68k-linux-gnu-objcopy

# Compiler flags
CFLAGS = -m68000 -O2 -Wall -Wextra -Iinclude -fomit-frame-pointer -nostdlib -ffreestanding
LDFLAGS = -T x68k.ld -nostdlib
ASFLAGS = -m68000

# Directories
SRCDIR = src
OBJDIR = build/obj
BINDIR = build/bin
FLOPPYDIR = build/floppy
TESTDIR = tests

# Target
TARGET = $(BINDIR)/helloa.x
BOOT_DISK = MasterDisk_V3.xdf

# Sources
C_SRCS = $(wildcard $(SRCDIR)/*.c $(SRCDIR)/*/*.c)
ASM_SRCS = $(wildcard $(SRCDIR)/*.s $(SRCDIR)/*/*.s)
C_OBJS = $(C_SRCS:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
ASM_OBJS = $(ASM_SRCS:$(SRCDIR)/%.s=$(OBJDIR)/%.o)
OBJS = $(ASM_OBJS) $(C_OBJS)

# Build rules
all: $(TARGET) install

$(TARGET): $(OBJS)
	@mkdir -p $(BINDIR)
	$(LD) $(LDFLAGS) -o $@.elf $^
	$(OBJCOPY) -O binary $@.elf $@
	@echo "Build successful: $(TARGET)"

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%.o: $(SRCDIR)/%.s
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) -o $@ $<

install: $(TARGET)
	@echo "Installing program to boot disk..."
	mcopy -i $(BOOT_DISK) -o $(TARGET) ::HELLOA.X
	@echo "Program installed to $(BOOT_DISK)"

clean:
	rm -rf $(OBJDIR) $(BINDIR)

test: install
	./tools/test.sh

.PHONY: all clean test install
```

**B. Linker Script** (`/home/armitage/git/x68000dev/x68k.ld`)

Defines X68000 memory layout (Human68k executable format):

```ld
OUTPUT_FORMAT("binary")
OUTPUT_ARCH(m68k)
ENTRY(_start)

MEMORY
{
    /* Human68k loads programs at 0x00006800 */
    ram : ORIGIN = 0x00006800, LENGTH = 1M
}

SECTIONS
{
    .text 0x00006800 : {
        *(.text.startup)
        *(.text)
        *(.text.*)
    } > ram

    .rodata : {
        *(.rodata)
        *(.rodata.*)
    } > ram

    .data : {
        *(.data)
        *(.data.*)
    } > ram

    .bss : {
        *(.bss)
        *(.bss.*)
        *(COMMON)
    } > ram
}
```

**C. Build Scripts**

`tools/build.sh`:
```bash
#!/bin/bash
set -e

cd "$(dirname "$0")/.."

echo "Cleaning build directory..."
make clean

echo "Building X68000 program..."
make all

echo "Build complete!"
```

`tools/clean.sh`:
```bash
#!/bin/bash
cd "$(dirname "$0")/.."
make clean
echo "Clean complete!"
```

`tools/test.sh`:
```bash
#!/bin/bash
set -e

cd "$(dirname "$0")/.."

BOOT_DISK="MasterDisk_V3.xdf"

if [ ! -f "$BOOT_DISK" ]; then
    echo "Error: Boot disk not found: $BOOT_DISK"
    exit 1
fi

# Verify program is on the disk
echo "Checking boot disk contents..."
mdir -i "$BOOT_DISK" :: | grep -i HELLOA.X || {
    echo "Error: HELLOA.X not found on boot disk"
    echo "Run 'make install' first"
    exit 1
}

echo "Running program in MAME with boot disk: $BOOT_DISK"

# Run MAME with auto-run Lua script
mame x68000 \
    -flop1 "$BOOT_DISK" \
    -window \
    -nomax \
    -resolution 768x512 \
    -script mame/autoboot.lua

echo "Test complete!"
```

**D. Install to Boot Disk** (`tools/install.sh`)

Copies program to the existing boot disk image:

```bash
#!/bin/bash
set -e

cd "$(dirname "$0")/.."

PROGRAM="${1:-build/bin/helloa.x}"
BOOT_DISK="MasterDisk_V3.xdf"

if [ ! -f "$PROGRAM" ]; then
    echo "Error: Program not found: $PROGRAM"
    echo "Run 'make all' first"
    exit 1
fi

if [ ! -f "$BOOT_DISK" ]; then
    echo "Error: Boot disk not found: $BOOT_DISK"
    exit 1
fi

echo "Installing $PROGRAM to $BOOT_DISK..."

# Copy program to boot disk (overwrite if exists)
mcopy -i "$BOOT_DISK" -o "$PROGRAM" ::HELLOA.X

echo "Installation complete!"
echo "Contents of boot disk:"
mdir -i "$BOOT_DISK" ::
```

---

### 5. MAME Automation with Lua Scripting

**A. MAME Lua Auto-Boot Script** (`mame/autoboot.lua`)

MAME supports Lua scripting for powerful automation without fragile window manipulation:

```lua
-- MAME X68000 Auto-boot and Test Script
-- Automatically executes program from floppy disk

local function main()
    -- Get machine and screen
    local machine = manager.machine
    local screen = machine.screens[":screen"]

    print("MAME X68000 Automation Started")

    -- Wait for boot to complete (Human68k prompt)
    emu.wait(8.0)

    -- Type command to execute program
    -- Simulates keyboard input: "A:HELLOA.X" + Enter
    manager.machine.input:seq_poll_start("keycode")

    -- Execute program from floppy
    local kbd = manager.machine.ioport

    -- Type: A:HELLOA.X
    typeKeys("A:HELLOA.X")
    emu.wait(0.5)

    -- Press Enter
    pressKey("ENTER")

    -- Let program run
    print("Program executing...")
    emu.wait(10.0)

    -- Take screenshot
    screen:snapshot("screenshot.png")
    print("Screenshot saved: screenshot.png")

    -- Keep running or exit based on configuration
    emu.wait(5.0)

    print("Test complete!")
end

function typeKeys(text)
    for i = 1, #text do
        local char = text:sub(i,i)
        -- Simulate key press for each character
        -- This is simplified - full implementation would map chars to keycodes
        emu.wait(0.1)
    end
end

function pressKey(keyname)
    -- Simulate key press
    emu.wait(0.1)
end

-- Start automation
emu.register_start(main)
```

**B. MAME Configuration** (`mame/mame.ini`)

Configure MAME for X68000 emulation:

```ini
# MAME Configuration for X68000

# ROM path (where x68000 BIOS is located)
rompath                   $HOME/.mame/roms

# Screenshot/snapshot settings
snapshot_directory        screenshots
snapname                  %g/%i

# Video settings
video                     opengl
window                    1
maximize                  0
resolution                768x512

# Speed throttle
throttle                  1
sleep                     1

# Skip startup warnings
skip_gameinfo             1
```

**C. Simplified Test Execution**

Instead of complex Python automation, MAME provides command-line control:

```bash
# Run with boot disk
mame x68000 \
    -flop1 MasterDisk_V3.xdf \
    -window \
    -nomax \
    -script mame/autoboot.lua

# Run with debugger enabled (for GDB)
mame x68000 \
    -flop1 MasterDisk_V3.xdf \
    -debug \
    -debugger gdbstub \
    -debugger_port 1234

# Run headless (no window) for CI/CD
mame x68000 \
    -flop1 MasterDisk_V3.xdf \
    -video none \
    -sound none \
    -seconds_to_run 30

# Take screenshot
mame x68000 \
    -flop1 MasterDisk_V3.xdf \
    -window \
    -snapname screenshot
```

---

### 6. GDB Debugging Integration

**A. MAME GDB Stub Support**

MAME includes built-in GDB stub for debugging m68k programs:

```bash
# Start MAME with GDB stub on port 1234
mame x68000 \
    -flop1 MasterDisk_V3.xdf \
    -window \
    -debug \
    -debugger gdbstub \
    -debugger_port 1234
```

**B. GDB Debugging Session** (`mame/debug_session.gdb`)

GDB script for common debugging tasks:

```gdb
# Connect to MAME GDB stub
target remote localhost:1234

# Set architecture
set architecture m68k

# Load symbols from ELF file (before objcopy)
file build/bin/helloa.x.elf

# Common breakpoints for X68000
# Break at program start
break _start

# Break at main
break main

# Display registers
define show_regs
    info registers
    x/8i $pc
end

# Continue execution
continue
```

**C. Debug Workflow**

1. **Build with debug symbols:**
```makefile
# Add -g flag for debugging
CFLAGS = -m68000 -O0 -g -Wall -Wextra -Iinclude -fomit-frame-pointer -nostdlib
```

2. **Start MAME with GDB stub:**
```bash
./tools/debug.sh
```

3. **Connect GDB:**
```bash
gdb-multiarch -x mame/debug_session.gdb
```

4. **Debug commands:**
```gdb
(gdb) break draw_rect    # Set breakpoint
(gdb) continue           # Run to breakpoint
(gdb) step               # Step into
(gdb) next               # Step over
(gdb) backtrace          # Stack trace
(gdb) info registers     # Show CPU registers
(gdb) x/16x 0xC00000     # Examine GVRAM
```

**D. Debug Helper Script** (`tools/debug.sh`)

```bash
#!/bin/bash
set -e

cd "$(dirname "$0")/.."

BOOT_DISK="MasterDisk_V3.xdf"

if [ ! -f "$BOOT_DISK" ]; then
    echo "Error: Boot disk not found: $BOOT_DISK"
    exit 1
fi

echo "Starting MAME with GDB stub on port 1234..."
echo "Connect with: gdb-multiarch -x mame/debug_session.gdb"

mame x68000 \
    -flop1 "$BOOT_DISK" \
    -window \
    -debug \
    -debugger gdbstub \
    -debugger_port 1234
```

---

### 7. Documentation (Beginner-Friendly)

**A. Setup Guide** (`docs/SETUP.md`)

- Ubuntu installation and configuration
- Installing MAME and cross-compiler
- Obtaining X68000 BIOS/ROM files legally
- Setting up Claude Code MCP servers
- Verifying installation

**B. Build System Guide** (`docs/BUILD.md`)

- How to compile X68000 programs
- Makefile usage and customization
- Understanding the linker script
- Creating floppy disk images
- Troubleshooting build errors

**C. Testing Guide** (`docs/TESTING.md`)

- How to run tests with MAME
- MAME Lua scripting basics
- Screenshot capture and validation
- Automated testing workflows
- CI/CD integration possibilities

**D. Debugging Guide** (`docs/DEBUGGING.md`)

- Using MAME's built-in debugger
- GDB debugging with MAME
- Setting breakpoints
- Examining memory and registers
- Common debugging scenarios
- Memory map reference

**E. X68000 Programming Primer** (`docs/X68000_GUIDE.md`)

- X68000 hardware overview
- Memory map and addressing
- IOCS system calls reference
- Human68k DOS calls
- Example programs with explanations

**F. Graphics Programming Reference** (`docs/GRAPHICS_API.md`)

- Graphics modes and capabilities
- Sprite handling
- Palette management
- GVRAM operations
- PCG (Programmable Character Generator)
- Practical examples for game development

---

### 8. Initial Example Program

Create minimal working program to verify entire pipeline:

**`src/main.c`** - Simple graphics test:

```c
/*
 * X68000 Graphics Test
 * Displays colored rectangles to verify graphics system
 *
 * This is a minimal Human68k executable that directly
 * accesses video memory.
 */

#define GVRAM ((volatile unsigned short *)0xC00000)
#define TEXT_VRAM ((volatile unsigned short *)0xE00000)

// IOCS system calls
#define IOCS_B_SUPER 0xFF30

void init_graphics() {
    // Enter supervisor mode for hardware access
    asm volatile (
        "move.l #0xFFFFFFFF, %%d0\n"
        "trap   #15\n"
        "dc.w   0xFF30\n"
        : : : "d0", "d1", "a0", "a1"
    );

    // Set 256-color graphics mode
    *(volatile unsigned short *)0xE82500 = 0x0004;
}

void draw_rect(int x, int y, int w, int h, unsigned char color) {
    volatile unsigned short *vram = GVRAM;
    for (int py = y; py < y + h; py++) {
        for (int px = x; px < x + w; px++) {
            vram[py * 512 + px] = color;
        }
    }
}

void main() {
    init_graphics();

    // Draw test pattern
    draw_rect(50, 50, 100, 100, 255);   // Red square
    draw_rect(200, 50, 100, 100, 240);  // Green square
    draw_rect(350, 50, 100, 100, 15);   // Blue square

    // Infinite loop
    while(1) {
        // Could add input handling here
        asm volatile ("nop");
    }
}
```

**Startup assembly** (`src/start.s`):

```assembly
# X68000 Human68k Program Startup
# Sets up minimal runtime environment

    .text
    .globl _start
    .globl main

_start:
    # Human68k loads program at 0x6800
    # Stack is already set up by OS

    # Save original stack pointer
    move.l  %sp, %a5

    # Set up our own stack (1MB)
    move.l  #0x100000, %sp

    # Clear BSS section (if needed)
    # bss_start and bss_end would be defined by linker

    # Call main C function
    jsr     main

    # If main returns, exit to Human68k
    move.w  #0xFF00, %d0        # DOS _EXIT call
    trap    #15
    dc.w    0xFF00

    # Should never reach here
    illegal
```

---

## Critical Files to Create/Modify

### Create New Files:

1. **`Makefile`** - Core build orchestration with m68k cross-compiler
2. **`x68k.ld`** - Linker script for Human68k memory layout
3. **`tools/build.sh`** - Build automation script
4. **`tools/clean.sh`** - Clean build artifacts
5. **`tools/install.sh`** - Install program to boot disk
6. **`tools/test.sh`** - MAME test execution script
7. **`tools/debug.sh`** - Launch MAME with GDB debugging
8. **`mame/autoboot.lua`** - MAME Lua automation script
9. **`mame/mame.ini`** - MAME configuration
10. **`mame/debug_session.gdb`** - GDB debugging script
11. **`tests/test_config.json`** - Test suite configuration
12. **`src/main.c`** - Initial example program with graphics
13. **`src/start.s`** - Human68k startup assembly code
14. **`config.mk`** - Build configuration variables
15. **`.gitignore`** - Ignore build artifacts and ROM files
16. **`docs/SETUP.md`** - Ubuntu setup and installation guide
17. **`docs/BUILD.md`** - Build system documentation
18. **`docs/TESTING.md`** - MAME testing guide
19. **`docs/DEBUGGING.md`** - GDB debugging guide
20. **`docs/X68000_GUIDE.md`** - X68000 programming primer
21. **`docs/GRAPHICS_API.md`** - Graphics programming reference
22. **`README.md`** - Project overview and quick start

### Move Existing Files:

1. **`MAGICAL.MDX`** → `assets/mdx/MAGICAL.MDX`
2. **`SPLASH.MDX`** → `assets/mdx/SPLASH.MDX`
3. **`PASSING.MDX`** → `assets/mdx/PASSING.MDX`
4. **`LAST.MDX`** → `assets/mdx/LAST.MDX`
5. **`mxdrv.x`** → `tools/mxdrv.x`

### Make Scripts Executable:

```bash
chmod +x tools/*.sh
```

---

## Known Problems and Drawbacks

### 1. **BIOS/ROM Requirements**
- **Problem:** MAME requires X68000 BIOS ROM files which are copyrighted
- **Impact:** Users must obtain ROMs legally (dump from own hardware or legal sources)
- **Mitigation:**
  - Clear documentation on legal ROM acquisition
  - Verify ROMs with `mame -verifyroms x68000`
  - Claude cannot provide ROM files
  - This is a one-time setup requirement

### 2. **Graphics Testing Challenges**
- **Problem:** Automated visual validation requires image comparison
- **Impact:** Pixel-perfect screenshots can be brittle
- **Mitigation:**
  - Use reference screenshots for regression testing
  - Consider perceptual hashing for fuzzy comparison
  - Manual validation for complex graphics
  - Focus on "does it run without crashing" for CI

### 3. **No Console Output from X68000 Programs**
- **Problem:** X68000 programs don't have stdout/stderr
- **Impact:** Cannot use printf() for debugging
- **Mitigation:**
  - Use GDB with MAME's gdbstub for breakpoint debugging
  - Create debug print functions that write to text VRAM
  - Use MAME's memory viewer
  - Design visual tests

### 4. **Cross-Compiler Limitations**
- **Problem:** Ubuntu's `m68k-linux-gnu-gcc` targets Linux, not bare metal
- **Impact:** May need additional flags for bare-metal programming
- **Alternative:** Build custom m68k-elf-gcc toolchain if needed
- **Mitigation:**
  - Use `-nostdlib -ffreestanding` flags
  - Provide our own startup code
  - Most simple programs work fine with this approach

### 5. **MAME Emulation Accuracy**
- **Problem:** MAME may not be 100% cycle-accurate for all X68000 models
- **Impact:** Subtle timing bugs may behave differently on real hardware
- **Mitigation:**
  - MAME X68000 emulation is generally very good
  - Test critical code paths on real hardware if available
  - Document any known discrepancies
  - For most development, MAME is sufficient

### 6. **Test Execution Speed**
- **Problem:** Emulator boot takes time
- **Impact:** Each test cycle takes ~10-15 seconds
- **Mitigation:**
  - MAME supports save states to skip boot
  - Use `-seconds_to_run` for automated testing
  - Batch multiple tests when possible
  - Much faster than real hardware!

### 7. **Lua Automation Complexity**
- **Problem:** MAME Lua scripting requires learning Lua and MAME's API
- **Impact:** Complex test automation may take time to develop
- **Mitigation:**
  - Start with simple command-line automation
  - Build Lua scripts incrementally
  - MAME documentation and community examples available
  - Command-line flags handle most simple cases

### 8. **Human68k Executable Format**
- **Problem:** X68000 uses Human68k .X executable format
- **Impact:** Need proper linker script and startup code
- **Mitigation:**
  - Provide working linker script in plan
  - Provide startup assembly template
  - Document format for reference
  - objcopy handles binary conversion

---

## Verification and Testing

### Phase 1: System Setup Verification

1. **Verify already-installed tools:**
   ```bash
   cd /home/armitage/git/x68000dev

   mame -version                    # Check MAME (already installed)
   m68k-linux-gnu-gcc --version     # Check cross-compiler (already installed)
   ls -lh MasterDisk_V3.xdf        # Verify boot disk exists
   ```

2. **Install additional utilities if needed:**
   ```bash
   sudo apt update
   sudo apt install -y build-essential git make mtools dosfstools

   # Optional: GDB for debugging
   sudo apt install -y gdb-multiarch

   # Optional: Node.js for MCP servers
   sudo apt install -y nodejs npm
   ```

3. **Verify X68000 BIOS ROMs (if not already done):**
   ```bash
   mame -verifyroms x68000
   ```
   - If ROMs are missing, they must be obtained legally
   - Place in `~/.mame/roms/x68000/`

4. **Test boot disk with MAME:**
   ```bash
   mame x68000 -flop1 MasterDisk_V3.xdf -window
   ```
   - Should boot to Human68k prompt
   - Press Ctrl+C to exit

5. **Optional MCP server setup:**
   - Add filesystem and git MCP servers to Claude Code config
   - Use path: `/home/armitage/git/x68000dev`
   - Restart Claude Code to load MCP servers

### Phase 2: Build System Verification

6. **Create directory structure:**
   ```bash
   cd /home/armitage/git/x68000dev

   # Create directories
   mkdir -p src include assets/mdx build/{obj,bin} tools mame docs tests

   # Move existing files
   mv MAGICAL.MDX SPLASH.MDX PASSING.MDX LAST.MDX assets/mdx/
   mv mxdrv.x tools/
   ```

7. **Build test program:**
   ```bash
   cd /home/armitage/git/x68000dev
   make all
   ```
   - Verify output: `build/bin/helloa.x` exists
   - Check for compilation errors
   - Program should be automatically installed to MasterDisk_V3.xdf

8. **Verify program on boot disk:**
   ```bash
   mdir -i MasterDisk_V3.xdf ::
   ```
   - Should show `HELLOA.X` file

### Phase 3: MAME Automation Verification

9. **Manual MAME test:**
   ```bash
   cd /home/armitage/git/x68000dev
   mame x68000 -flop1 MasterDisk_V3.xdf -window
   ```
   - Wait for Human68k boot (A> prompt)
   - Manually type: `HELLOA.X`
   - Press Enter
   - Verify colored rectangles appear

10. **Automated test:**
    ```bash
    cd /home/armitage/git/x68000dev
    make test
    ```
    - MAME should launch automatically
    - Program should execute (via Lua script)
    - Screenshot captured (if configured)
    - Emulator exits after timeout

11. **Claude integration test:**
    - Ask Claude: "Build and test the X68000 program"
    - Claude should execute build and test via Bash tool
    - Claude should report build success and test results

### Phase 4: Debugging Verification

12. **GDB debugging test:**
    ```bash
    cd /home/armitage/git/x68000dev

    # Terminal 1: Start MAME with GDB stub
    ./tools/debug.sh

    # Terminal 2: Connect GDB
    gdb-multiarch -x mame/debug_session.gdb
    ```
    - Set breakpoint at `main`
    - Continue execution
    - Verify breakpoint hit
    - Examine registers and memory

### Phase 5: Documentation Verification

13. **Review documentation:**
    - Read `docs/SETUP.md` - verify Ubuntu setup is clear
    - Read `docs/BUILD.md` - verify build process is clear
    - Read `docs/TESTING.md` - verify MAME testing is clear
    - Read `docs/DEBUGGING.md` - verify GDB workflow is clear
    - Read `docs/X68000_GUIDE.md` - verify beginner-friendly
    - Read `docs/GRAPHICS_API.md` - verify useful for game dev

### Phase 6: Iteration Test

14. **Make a code change:**
    ```bash
    cd /home/armitage/git/x68000dev

    # Modify src/main.c to change rectangle colors or positions
    # Then rebuild and test
    make clean
    make all
    make test
    ```
    - Verify changes appear when MAME runs
    - Confirm full automation works end-to-end

### Success Criteria

- ✅ Ubuntu packages installed correctly
- ✅ X68000 ROMs verified in MAME
- ✅ Claude can compile X68000 programs via Bash tool
- ✅ Build errors reported clearly
- ✅ Programs execute in MAME automatically
- ✅ Screenshots captured successfully
- ✅ GDB debugging works with MAME
- ✅ Full build-test cycle under 30 seconds
- ✅ Documentation is clear and beginner-friendly
- ✅ Can iterate on graphics code rapidly
- ✅ No manual intervention required for build-test cycle

---

## Next Steps After Approval

1. **Verify system setup (already mostly complete):**
   ```bash
   cd /home/armitage/git/x68000dev
   mame -version                    # ✓ Already installed
   m68k-linux-gnu-gcc --version     # ✓ Already installed
   ls -lh MasterDisk_V3.xdf        # ✓ Boot disk present
   ```

2. **Install additional utilities:**
   ```bash
   sudo apt install -y mtools dosfstools gdb-multiarch
   ```

3. **Create directory structure:**
   ```bash
   mkdir -p src include assets/mdx build/{obj,bin} tools mame docs tests
   mv MAGICAL.MDX SPLASH.MDX PASSING.MDX LAST.MDX assets/mdx/
   mv mxdrv.x tools/
   ```

4. **Create build system:**
   - Create `Makefile` with m68k cross-compiler
   - Create `x68k.ld` linker script for Human68k
   - Create `tools/build.sh`, `tools/clean.sh`, `tools/install.sh`
   - Create `.gitignore`

5. **Create initial program:**
   - Write `src/start.s` (startup assembly)
   - Write `src/main.c` (graphics test)
   - Build: `make all`
   - Verify: `mdir -i MasterDisk_V3.xdf ::`

6. **Create MAME automation:**
   - Create `mame/mame.ini` (MAME configuration)
   - Create `mame/autoboot.lua` (auto-boot script)
   - Create `tools/test.sh` (test execution)
   - Test: `make test`

7. **Create debugging setup:**
   - Create `mame/debug_session.gdb` (GDB script)
   - Create `tools/debug.sh` (debug helper)
   - Test GDB connection

8. **Create documentation:**
   - `docs/SETUP.md` - Setup guide
   - `docs/BUILD.md` - Build guide
   - `docs/TESTING.md` - Testing guide
   - `docs/DEBUGGING.md` - Debugging guide
   - `docs/X68000_GUIDE.md` - X68000 primer
   - `docs/GRAPHICS_API.md` - Graphics reference
   - `README.md` - Project overview

9. **Verification:**
   - Test complete build-test cycle
   - Verify Claude can use Bash tool for all operations
   - Test iteration workflow
   - Test debugging workflow

10. **Git commit and push:**
    - Commit all changes with descriptive message
    - Push to branch `claude/x68000-build-environment-rP5TG`

---

## Advantages of Linux/MAME Approach

This Linux-based approach with MAME provides significant advantages over Windows/XM6G:

### **1. Superior Automation**
- **Command-line first:** MAME is designed for scripting and automation
- **No GUI automation fragility:** No PyAutoGUI, no window focus issues
- **Lua scripting:** Powerful automation within MAME itself
- **Headless mode:** Can run tests without display (CI/CD ready)

### **2. Professional Debugging**
- **GDB integration:** Full source-level debugging with breakpoints
- **Memory inspection:** MAME's built-in debugger with watch points
- **Single-step execution:** Step through assembly and C code
- **Industry-standard tools:** Same GDB workflow as other embedded development

### **3. Simpler Architecture**
- **No custom MCP servers needed:** Built-in Bash tool is sufficient
- **Standard Linux tools:** Uses familiar make, bash, mtools
- **Clean automation:** Direct command-line control
- **No Windows dependencies:** Cross-platform and portable

### **4. Better Developer Experience**
- **Faster iteration:** Linux toolchain is generally faster
- **Familiar workflow:** Standard Unix development environment
- **Better documentation:** MAME has extensive community documentation
- **Open source:** MAME and toolchain are fully open source

### **5. Future Expandability**
- **CI/CD ready:** Can run in GitHub Actions or GitLab CI
- **Docker compatible:** Easy to containerize
- **Scriptable:** Easy to extend with additional automation
- **Multiple emulators:** Can add other emulators alongside MAME

### **6. Cost-Effective**
- **Free software:** All tools are free and open source
- **No Windows license needed:** Ubuntu is free
- **Standard hardware:** Runs on any modern Linux system
- **Cloud compatible:** Can run on cloud VMs for CI/CD

The only tradeoff is the BIOS/ROM requirement, which is a one-time legal acquisition that users must handle themselves.
