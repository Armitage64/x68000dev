# X68000 Debugging Guide

This guide explains how to debug X68000 programs using MAME and GDB.

## Quick Start

### Terminal 1: Start MAME with GDB Stub

```bash
./tools/debug.sh
```

### Terminal 2: Connect GDB

```bash
gdb-multiarch -x mame/debug_session.gdb
```

Now you can use standard GDB commands to debug your X68000 program!

## Debugging Methods

### 1. GDB with MAME GDB Stub (Recommended)

MAME includes a built-in GDB stub that allows source-level debugging.

**Advantages:**
- Set breakpoints in C code
- Step through code line-by-line
- Inspect variables and memory
- View call stack
- Industry-standard tool

**Limitations:**
- Requires symbols (build with `-g`)
- Some optimizations may confuse debugger

### 2. MAME Built-in Debugger

MAME has a powerful built-in debugger.

```bash
mame x68000 -flop1 MasterDisk_V3.xdf -window -debug
```

**Advantages:**
- No external tools needed
- Direct hardware inspection
- Memory and register viewers
- Disassembly view

**Limitations:**
- No source-level debugging
- Assembly-focused interface
- Steeper learning curve

### 3. Printf-Style Debugging

Since X68000 programs have no stdout, alternatives:

**Option A: Write to Text VRAM**

```c
void debug_print(const char *msg, int x, int y) {
    volatile unsigned short *text_vram = (volatile unsigned short *)0xE00000;
    int i = 0;
    while (msg[i]) {
        text_vram[(y * 128) + x + i] = msg[i];
        i++;
    }
}
```

**Option B: Use Memory as Log Buffer**

```c
#define DEBUG_LOG_SIZE 1024
char debug_log[DEBUG_LOG_SIZE];
int debug_log_pos = 0;

void debug_log_str(const char *msg) {
    while (*msg && debug_log_pos < DEBUG_LOG_SIZE) {
        debug_log[debug_log_pos++] = *msg++;
    }
}
```

Then examine with GDB: `x/1024c &debug_log`

## GDB Debugging

### Setup

1. **Build with debug symbols:**

Edit `Makefile` to add `-g` and disable optimization:

```makefile
CFLAGS = -m68000 -O0 -g -Wall -Wextra -Iinclude \
         -fomit-frame-pointer -nostdlib -ffreestanding
```

2. **Rebuild:**

```bash
make clean && make all
```

3. **Start MAME with GDB stub:**

```bash
./tools/debug.sh
```

4. **Connect GDB:**

```bash
gdb-multiarch -x mame/debug_session.gdb
```

### Essential GDB Commands

#### Navigation

```gdb
(gdb) continue         # Resume execution
(gdb) step             # Step into (line by line)
(gdb) next             # Step over (skip function calls)
(gdb) finish           # Run until function returns
(gdb) until 50         # Run until line 50
```

#### Breakpoints

```gdb
(gdb) break main                    # Break at function
(gdb) break src/main.c:42           # Break at line 42
(gdb) break *0x6800                 # Break at address
(gdb) info breakpoints              # List breakpoints
(gdb) delete 1                      # Delete breakpoint #1
(gdb) disable 2                     # Disable breakpoint #2
(gdb) enable 2                      # Enable breakpoint #2
```

#### Inspection

```gdb
(gdb) print x                       # Print variable
(gdb) print/x color                 # Print in hex
(gdb) print *((int*)0xC00000)       # Dereference address
(gdb) info registers                # Show all registers
(gdb) info locals                   # Show local variables
(gdb) backtrace                     # Show call stack
(gdb) frame 2                       # Switch to frame 2
```

#### Memory Examination

```gdb
(gdb) x/16x 0xC00000                # Examine 16 words (hex)
(gdb) x/16i $pc                     # Disassemble at PC
(gdb) x/s 0x10000                   # Show string
(gdb) x/16c &debug_log              # Show chars
```

Format specifiers:
- `x` - Hexadecimal
- `d` - Decimal
- `u` - Unsigned decimal
- `o` - Octal
- `t` - Binary
- `a` - Address
- `c` - Character
- `s` - String
- `i` - Instruction

#### Watchpoints

```gdb
(gdb) watch x                       # Break when x changes
(gdb) rwatch x                      # Break when x is read
(gdb) awatch x                      # Break on read or write
```

#### Register Access

```gdb
(gdb) print $d0                     # Data register 0
(gdb) print $a0                     # Address register 0
(gdb) print $pc                     # Program counter
(gdb) print $sp                     # Stack pointer
(gdb) set $d0 = 0x1234              # Modify register
```

### Debugging Common Issues

#### Program Doesn't Reach `main`

```gdb
(gdb) break _start
(gdb) continue
(gdb) step
```

Check that `_start` correctly calls `main`.

#### Graphics Don't Appear

```gdb
(gdb) break draw_rect
(gdb) continue
(gdb) print x
(gdb) print y
(gdb) print color
(gdb) x/16x 0xC00000              # Check GVRAM
```

Verify function is called and GVRAM is being written.

#### Program Crashes

```gdb
(gdb) catch signal                 # Catch all signals
(gdb) continue
```

When it crashes:

```gdb
(gdb) backtrace                    # See call stack
(gdb) info registers               # Check register values
(gdb) x/16i $pc-20                 # Disassemble around crash
```

#### Infinite Loop

```gdb
(gdb) Ctrl+C                       # Interrupt
(gdb) backtrace                    # Where are we?
(gdb) list                         # Show source
(gdb) x/16i $pc                    # Show instructions
```

## MAME Built-in Debugger

### Launching

```bash
mame x68000 -flop1 MasterDisk_V3.xdf -window -debug
```

A debugger window will open alongside the emulation window.

### Basic Commands

```
go                    - Resume execution
step                  - Step one instruction
over                  - Step over (skip subroutines)
out                   - Run until return
bp 6800               - Set breakpoint at address
bpclear               - Clear all breakpoints
print d0              - Print register d0
dump 0xC00000,100     - Dump memory
dasm 6800,20          - Disassemble 20 instructions
```

### Memory Viewer

Press Tab, select "Memory" to view:
- GVRAM (0xC00000)
- Text VRAM (0xE00000)
- System RAM
- ROM

### Register Viewer

Shows all 68000 registers:
- D0-D7 (data registers)
- A0-A7 (address registers)
- PC (program counter)
- SR (status register)

## X68000 Memory Map Reference

Common addresses for debugging:

### Graphics

```
0xC00000 - GVRAM (graphics)
0xE00000 - Text VRAM
0xE82500 - Graphics mode register
```

### System

```
0x00000000 - ROM (1MB)
0x00C00000 - Main RAM
0x00EB0000 - System work area
```

### I/O

```
0x00E80000 - CRTC registers
0x00E82000 - Video control
0x00E88000 - OPM (sound)
0x00E90000 - Keyboard
```

## Debugging Workflow

### 1. Reproduce the Bug

Build and run until the bug occurs:

```bash
make clean && make all && make test
```

### 2. Form a Hypothesis

What might be wrong?
- Logic error?
- Memory corruption?
- Uninitialized variable?
- Hardware access issue?

### 3. Set Strategic Breakpoints

```gdb
break main
break init_graphics
break draw_rect
```

### 4. Inspect State

At each breakpoint:
- Check variables
- Examine memory
- Verify register values
- Review call stack

### 5. Fix and Verify

Make the fix, rebuild, test:

```bash
make clean && make all && make test
```

### 6. Add Regression Test

Document the bug and the fix to prevent regression.

## Tips and Tricks

### Use Custom GDB Commands

Add to `mame/debug_session.gdb`:

```gdb
define show_gvram
    x/256x 0xC00000
end

define show_text
    x/128x 0xE00000
end
```

### Log to a File

```bash
gdb-multiarch -x mame/debug_session.gdb 2>&1 | tee debug.log
```

### Remote Debugging

GDB can connect from another machine:

```bash
# On MAME machine
./tools/debug.sh

# On development machine
gdb-multiarch
(gdb) target remote 192.168.1.100:1234
(gdb) file build/bin/helloa.x.elf
```

### Use Save States

1. Run to interesting point
2. Save state (F7 in MAME)
3. Test fixes quickly by loading state

## Common Debugging Scenarios

### Scenario: Wrong Colors

```gdb
(gdb) break draw_rect
(gdb) continue
(gdb) print color        # Check color value
(gdb) x/1x GVRAM + (y*512 + x)  # Check what's written
```

### Scenario: Crash in Graphics Init

```gdb
(gdb) break init_graphics
(gdb) continue
(gdb) step               # Step through init
(gdb) info registers     # Check if supervisor mode enabled
```

### Scenario: Function Not Called

```gdb
(gdb) break draw_rect
(gdb) continue
# If doesn't stop, function isn't being called
(gdb) break main
(gdb) continue
(gdb) step               # Trace execution
```

## Next Steps

- Read [X68000_GUIDE.md](X68000_GUIDE.md) - Understand the hardware
- Read [GRAPHICS_API.md](GRAPHICS_API.md) - Graphics programming
- Practice with the example program
