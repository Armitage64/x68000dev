# X68000 Test Harness Development Skill

## Overview

This skill provides expertise in developing and debugging programs for the Sharp X68000 vintage computer using MAME emulation, with automated testing via Lua validation scripts.

## When to Use This Skill

Use this skill when:
- Building Motorola 68000 assembly or C programs for the X68000
- Setting up automated MAME-based testing for retro computer projects
- Debugging position-dependent code issues on m68k targets
- Implementing F-line exception handlers (Human68k DOS calls)
- Working with floppy disk images and Human68k `.X` executables

## Key Architecture

### X68000 Platform
- **CPU:** Motorola 68000 @ 10 MHz (16-bit data bus, 24-bit address space)
- **OS:** Human68k (Sharp's proprietary DOS-like OS)
- **Memory map:**
  - `0x000000–0x0FFFFF`: Main RAM (1 MB)
  - `0x006800`: Typical program load address (first free user space after OS)
  - `0xC00000–0xDFFFFF`: Graphics VRAM (GVRAM)
  - `0xE00000–0xE7FFFF`: Text VRAM (TVRAM, 128 KB)
  - `0xE80000+`: I/O registers (CRTC, DMA, sound, etc.)
  - `0xFF0000–0xFFFFFF`: System ROM (BIOS/IOCS)

### Human68k DOS Calls
- **Not TRAP #15** — that's IOCS (hardware BIOS, e.g., `_B_PRINT`)
- **F-line exceptions** (`dc.w $FFxx`) — software interrupts for DOS services
  - `$FF09` = `_PRINT` — print null-terminated string (address on stack)
  - `$FF00` = `_EXIT` — terminate process and return to shell
  - When the CPU executes `0xFFxx`, it takes the F-line exception (vector 11 @ `0x002C`)
  - Human68k's F-line handler reads the opcode, extracts the function number, and dispatches

### Human68k `.X` Executable Format
64-byte header + payload:

| Offset | Size | Field         | Notes                                      |
|--------|------|---------------|--------------------------------------------|
| 0x00   | 2    | Magic         | `HU` (0x48, 0x55)                          |
| 0x02   | 2    | Reserved      | 0x0000                                     |
| 0x04   | 4    | Base address  | 0 = relocatable; non-zero = fixed address |
| 0x08   | 4    | Entry offset  | Offset from load base to `_start`         |
| 0x0C   | 4    | text_size     | Size of code section (bytes)               |
| 0x10   | 4    | data_size     | Size of initialized data                   |
| 0x14   | 4    | bss_size      | Size of uninitialized data (zero-filled)   |
| 0x18   | 4    | reloc_size    | Size of relocation table (0 for PIC)       |
| 0x1C   | 4    | symbol_size   | Size of symbol table                       |
| 0x20   | 4    | line_size     | Size of line number info                   |
| 0x24   | 12   | Reserved      | Padding/flags                              |
| 0x30   | 16   | Reserved      | More padding                               |
| 0x40   | N    | Payload       | Raw machine code and data                  |

**Critical detail:** If `base_address = 0`, Human68k loads the program at whatever
free memory is available (typically `0x7000`–`0x8000` after drivers). The program
MUST be position-independent or it will crash with illegal instruction faults.

## Build Pipelines

### Assembly (VASM → native `.X`)
```bash
./tools/vasmm68k_mot -Fxfile -nosym -o build/bin/program.x src/hello.s
```
VASM's `-Fxfile` output mode writes a native Human68k `.X` file directly, with
proper header. Use PC-relative addressing (`pea msg(pc)`) for position independence.

### C (GCC → ELF → raw binary → `.X` header wrap)
```bash
# 1. Compile with -mpcrel (critical!)
m68k-linux-gnu-gcc -m68000 -nostdlib -ffreestanding \
    -fno-builtin -fomit-frame-pointer -mpcrel \
    -c src/helloc.c -o build/obj/helloc.o

# 2. Assemble minimal crt0 startup
m68k-linux-gnu-as -m68000 src/crt0.s -o build/obj/crt0.o

# 3. Link (origin 0x6800 for symbol assignment only)
m68k-linux-gnu-ld -T x68k.ld -o build/bin/helloc.elf \
    build/obj/crt0.o build/obj/helloc.o

# 4. Extract raw binary (strip ELF container)
m68k-linux-gnu-objcopy -O binary build/bin/helloc.elf build/bin/helloc.bin

# 5. Prepend .X header (64 bytes, base_address=0 for relocatable)
python3 tools/make_xfile.py build/bin/helloc.bin build/bin/helloc.x
```

**Linker script (`x68k.ld`):**
```ld
OUTPUT_ARCH(m68k)
ENTRY(_start)

MEMORY { ram : ORIGIN = 0x00006800, LENGTH = 1M }

SECTIONS {
    .text 0x00006800 : { *(.text.startup) *(.text) *(.text.*) } > ram
    .rodata          : { *(.rodata) *(.rodata.*) } > ram
    .data            : { *(.data) *(.data.*) } > ram
    .bss             : { *(.bss) *(.bss.*) *(COMMON) } > ram
}
```

**Minimal `crt0.s`:**
```asm
    .global _start
    .text
_start:
    jsr     main(%pc)   /* PC-relative call — position independent */
    .word   0xFF00      /* DOS _EXIT (F-line opcode) */
```

## Critical Lessons Learned

### 1. The `-mpcrel` Flag is Mandatory for C Programs

**Problem:** Without `-mpcrel`, GCC generates absolute addresses:
```asm
main:
    pea     $6826       ; absolute address — only works at exactly 0x6800!
    jsr     dos_print
```

If Human68k loads the program at `0x7800` (because `base_address = 0`), the `pea
$6826` instruction pushes the wrong address. The `_PRINT` handler tries to read
from `0x6826` (which is unrelated memory), and execution goes off the rails.

**Symptom:** "Illegal instruction executed (PC=$00007FBA)" — PC is far from the
expected code region because the CPU jumped into garbage.

**Solution:** Always use `-mpcrel`:
```asm
main:
    pea     %pc@(6826)  ; PC-relative — works at any load address!
    jsr     dos_print(%pc)
```

At runtime, if loaded at `0x7800`, the PC-relative offset resolves correctly:
`0x7800 + offset = 0x7826` (the actual string location after relocation).

**Verification:**
```bash
m68k-linux-gnu-objdump -d build/bin/helloc.elf | grep pea
```
- ✓ Good: `pea %pc@(offset)` or `487a dddd` opcode
- ✗ Bad: `pea $absolute` or `4879 xxxx xxxx` opcode

### 2. Never Set `base_address = 0x6800` in the Header

**Problem:** Setting `base_address = 0x6800` in the `.X` header forces Human68k to
load the program at exactly `0x6800`. But if command.x (the shell) is already
loaded at or near `0x6800`, this causes a collision — the program overwrites the
shell's code in memory.

**Symptom:** "Bus error has occurred (SR=$2019:PC=$02FF055A)" — PC is in the BIOS
ROM area (`$FF055A` in 24-bit space). The corruption causes the F-line handler to
fault while executing inside the OS.

**Solution:** Always use `base_address = 0` (relocatable) and rely on `-mpcrel` to
generate position-independent code. Human68k will load the program at the first
free address (typically `0x7000`–`0x8000` depending on resident drivers).

### 3. TVRAM Scan Must Handle Hardware Scroll

**Problem:** The X68000 uses hardware scrolling — the CRTC scroll register advances
as the terminal scrolls, so the visible text is at a variable offset within the
TVRAM plane. A naive scan of `0xE00000`–`0xE001FF` (first 256 cells) misses text
that has scrolled past that region.

**Symptom:** Test reports "TEST PARTIAL — program loaded but no screen output" even
though the screenshot shows both programs ran successfully. The first 256 TVRAM
cells are stale/blank because the text scrolled to a higher offset.

**Solution:** Sample across the full 32 KB text plane with a stride:
```lua
-- Sample every 4th cell across 0xE00000–0xE07FFF (16384 cells total)
for i = 0, 16383, 4 do
    local addr = 0xE00000 + i * 2
    local ok, val = pcall(function() return mem:read_u16(addr) end)
    if ok and val ~= 0 then
        tvram_hits = tvram_hits + 1
    end
end
```

A stride of 4 gives 4096 iterations (fast enough) while covering any 25-character
line of text regardless of its TVRAM offset.

### 4. MAME Warning Dismissal Requires Two Mechanisms

**Problem:** MAME shows an "imperfect emulation" warning on X68000 boot. The warning
must be dismissed before execution can proceed, but automated dismissal is tricky
because SDL2 filters synthetic input events.

**Solution (dual approach):**

1. **Config pre-patch** — set `warned="9999999999"` in `~/.mame/cfg/x68000.cfg`
   before every launch. MAME compares this timestamp against the current launch
   time; because 9999999999 (year 2286) is always in the future, no warning shows.
   Must run on every invocation because MAME resets `warned` to the real dismissal
   timestamp at session exit.

2. **XTEST fallback click** — `xdotool mousemove CX CY; xdotool click 1` (no
   `--window` flag). Without `--window`, xdotool uses `XTestFakeButtonEvent` instead
   of `XSendEvent`. SDL2 silently ignores XSendEvent but accepts XTEST as real input.

The cfg patch works 99% of the time; the XTEST click is a fallback in case the cfg
file wasn't read (e.g., first run, permissions issue).

### 5. Use `-nomouse` to Prevent Spurious Input

**Problem:** After the program exits and returns to the Human68k prompt, the emulated
mouse continues tracking the host cursor position, appearing as continuous input to
the X68000 OS (the analog mouse port reads host coordinates injected by xdotool).

**Solution:** Pass `-nomouse` to MAME. The X68000 analog mouse hardware is disabled,
so the xdotool cursor movement (used for warning dismissal) doesn't leak into the
running OS after the program finishes.

## X68000 Graphics Programming

### Graphics Hardware Architecture

The X68000 has multiple graphics subsystems that must be coordinated:

**Memory Map:**
- `0xC00000–0xDFFFFF`: Graphics VRAM (GVRAM) - 1024×1024×4 planes
- `0xE82000–0xE8201F`: Sprite palette RAM (16 colors × 16 palettes × 2 bytes)
- `0xE82500`: Graphics mode/control register
- `0xE82600`: Video control register (layer priority, enable/disable)
- `0xEB0000–0xEB07FF`: Sprite attribute table (128 sprites × 16 bytes)
- `0xEB8000–0xEBFFFF`: PCG (Pattern Color Generator) sprite pattern RAM (32 KB)

**Video Control Register (0xE82600):**
```
Bit 15-11: Reserved
Bit 10:    AH (high-resolution mode)
Bit  9:    YS (vertical resolution)
Bit  8:    Exon (external sync enable)
Bit  7:    HP (horizontal frequency)
Bit  6:    SON (sprite on/off) - 1 = enable sprites
Bit  5:    BP (back page select)
Bit  4:    GS3 (graphic screen 3 on/off)
Bit  3:    GS2 (graphic screen 2 on/off)
Bit  2:    GS1 (graphic screen 1 on/off)
Bit  1:    GS0 (graphic screen 0 on/off) - 1 = enable graphics plane 0
Bit  0:    TS (text screen on/off)
```

**Graphics Modes (via IOCS _CRTMOD):**
- Mode 4: 512×512, 16 colors (4 bitplanes)
- Mode 6: 512×512, 256 colors (8 bitplanes)
- Mode 8: 256×256, 65536 colors (16 bits per pixel)
- Mode 16: 768×512, 16 colors (high resolution)

### IOCS Graphics Functions

Always prefer IOCS functions over direct hardware access:

**Screen Mode Control:**
- `_CRTMOD` (0x10): Set graphics mode
  ```asm
  move.w  #4,-(sp)        ; Mode 4 = 512×512, 16-color
  move.w  #$10,d0         ; IOCS _CRTMOD
  trap    #15
  addq.l  #2,sp
  ```

- `_G_CLR_ON` (0x16): Clear graphics screen and enable graphics
  ```asm
  move.w  #$16,d0         ; IOCS _G_CLR_ON
  trap    #15             ; No parameters needed
  ```

- `_VPAGE` (0x12): Select active video page
  ```asm
  move.w  #0,-(sp)        ; Page 0
  move.w  #$12,d0         ; IOCS _VPAGE
  trap    #15
  addq.l  #2,sp
  ```

- `_B_CUROFF` (0x13): Turn off text cursor
  ```asm
  move.w  #$13,d0         ; IOCS _B_CUROFF
  trap    #15
  ```

**Drawing Primitives:**
- `_PSET` (0x80): Plot pixel - `PSET(x, y, color)`
- `_LINE` (0x81): Draw line - `LINE(x1, y1, x2, y2, color, linestyle)`
- `_BOX` (0x82): Draw box outline - `BOX(x1, y1, x2, y2, color, linestyle)`
- `_FILL` (0x87): Fill box - `FILL(x1, y1, x2, y2, color)`
- `_CIRCLE` (0x88): Draw circle - `CIRCLE(x, y, radius, color)`

**IMPORTANT:** Stack parameter order is **right-to-left**. For `PSET(x, y, color)`:
```asm
move.w  #15,-(sp)       ; color (rightmost parameter)
move.w  #100,-(sp)      ; y (middle parameter)
move.w  #100,-(sp)      ; x (leftmost parameter)
move.w  #$80,d0         ; IOCS _PSET
trap    #15
lea     6(sp),sp        ; Clean up 3 words = 6 bytes
```

### PCG Sprite System

**Sprite Format:**
- Each sprite pattern is 16×16 pixels
- 4 bits per pixel (16 colors)
- 128 bytes per pattern (16 rows × 8 bytes per row)
- 256 patterns maximum in PCG RAM

**Pixel Packing:**
Each byte contains 2 pixels as nibbles:
```
Byte N: [Pixel 2N+1 (high nibble)][Pixel 2N (low nibble)]

Example row (16 pixels = 8 bytes):
Byte 0: [Pixel 1][Pixel 0]
Byte 1: [Pixel 3][Pixel 2]
...
Byte 7: [Pixel 15][Pixel 14]
```

**Loading Sprite Pattern to PCG RAM:**
```asm
; Enter supervisor mode first
move.l  #$10000,-(sp)
move.w  #$30,d0         ; IOCS _B_SUPER
trap    #15
addq.l  #4,sp

; Copy 128 bytes to PCG RAM
lea     sprite_data,a0
lea     $EB8000,a1      ; PCG RAM base (pattern 0)
move.w  #127,d0         ; 128 bytes - 1
.loop:
    move.b  (a0)+,(a1)+
    dbra    d0,.loop
```

**Sprite Control Structure (16 bytes per sprite at 0xEB0000):**
```
+0: ctrl (word)     - bit 0: 1=show, 0=hide
+2: x_pos (word)    - horizontal position (0-1023)
+4: y_pos (word)    - vertical position (0-1023)
+6: pattern (word)  - pattern number (0-255)
+8: priority (word) - display priority (0-3)
+10: color (word)   - palette number (0-15)
+12-15: reserved
```

**Configuring Sprite 0:**
```asm
lea     $EB0000,a0      ; Sprite control base
move.w  #1,(a0)         ; +0: Enable sprite
move.w  #256,2(a0)      ; +2: X position = 256 (center)
move.w  #256,4(a0)      ; +4: Y position = 256 (center)
move.w  #0,6(a0)        ; +6: Use pattern 0
move.w  #3,8(a0)        ; +8: Priority 3 (topmost)
move.w  #0,10(a0)       ; +10: Use palette 0
```

**Palette Format (5-5-5 RGB):**
Each color is a 16-bit word: `GGGGGRRRRRBBBBB` (bit 0 is typically 0)
```asm
; Load palette to sprite palette 0
lea     palette_data,a0
lea     $E82000,a1      ; Palette RAM base
move.w  #15,d0          ; 16 colors - 1
.loop:
    move.w  (a0)+,(a1)+ ; Copy 16-bit color word
    dbra    d0,.loop
```

**Enabling Sprite Layer:**
```asm
; Set bit 6 (SON) in video control register
lea     $E82600,a0
move.w  (a0),d0
ori.w   #$0040,d0       ; Set bit 6 (SON)
move.w  d0,(a0)
```

### Graphics Initialization Sequence

**Recommended sequence (IOCS-first, then hardware):**

```asm
start:
    ; 1. Print startup message (while still in text mode)
    pea     start_msg(pc)
    dc.w    $ff09           ; DOS _PRINT
    addq.l  #4,sp

    ; 2. Initialize graphics mode via IOCS (stays in user mode)
    move.w  #4,-(sp)        ; Mode 4: 512×512, 16-color
    move.w  #$10,d0         ; IOCS _CRTMOD
    trap    #15
    addq.l  #2,sp

    move.w  #0,-(sp)        ; Select page 0
    move.w  #$12,d0         ; IOCS _VPAGE
    trap    #15
    addq.l  #2,sp

    move.w  #$16,d0         ; IOCS _G_CLR_ON
    trap    #15             ; Clear screen and enable graphics

    move.w  #$13,d0         ; IOCS _B_CUROFF
    trap    #15             ; Turn off cursor

    ; 3. Enter supervisor mode for hardware access
    move.l  #$10000,-(sp)   ; Pass dummy stack pointer
    move.w  #$30,d0         ; IOCS _B_SUPER
    trap    #15
    addq.l  #4,sp

    ; 4. Load palette
    bsr     load_palette

    ; 5. Load sprite patterns
    bsr     load_sprite_pattern

    ; 6. Configure sprite
    bsr     setup_sprite

    ; 7. Enable sprite layer in VIDEO_CTRL
    lea     $E82600,a0
    move.w  (a0),d0
    ori.w   #$0040,d0       ; Set bit 6 (SON)
    move.w  d0,(a0)

    ; 8. Infinite loop (wait for keypress or VSync)
.wait:
    bra     .wait
```

### Known Graphics Issues and Troubleshooting

#### Issue 1: Graphics Layer Not Visible

**Symptom:** IOCS _G_CLR_ON clears the screen to black, but graphics primitives
(_PSET, _LINE, _BOX) produce no visible output despite executing without error.

**Observed behavior:**
- Screen successfully switches from text mode to graphics mode (black screen)
- IOCS calls return success (no crashes or illegal instructions)
- GVRAM contains written data (confirmed via memory diagnostics)
- Direct GVRAM writes at 0xC00000 also produce no visible output
- Video Control Register shows correct bits set (GS0 enabled)

**Attempted fixes that did NOT work:**
1. Setting VIDEO_CTRL bit 1 (GS0) manually - no change
2. Direct GVRAM writes instead of IOCS - data written but not visible
3. Different graphics modes (4, 6, 8, 16) - same result across all modes
4. Writing solid blocks to GVRAM - no pixels appear on screen
5. Using _FILL instead of _PSET - executes but produces no output

**Current hypothesis:**
- IOCS graphics layer priority/mixing may be misconfigured
- Possible palette RAM not initialized for graphics planes (separate from sprite palette)
- Graphics mode register (0xE82500) may need additional configuration beyond _CRTMOD
- GVRAM page mapping may differ from expected in different graphics modes

**Workaround:** None identified yet. Text mode output via DOS _PRINT works reliably.

**Diagnostic approach:**
```lua
-- MAME Lua script to check graphics registers
local mem = manager.machine.devices[":maincpu"].spaces["program"]
local gfx_mode = mem:read_u16(0xE82500)
local video_ctrl = mem:read_u16(0xE82600)
print(string.format("GFX Mode: 0x%04X, Video Ctrl: 0x%04X", gfx_mode, video_ctrl))

-- Sample GVRAM for written data
local gvram_hits = 0
for i = 0, 1023, 4 do
    local addr = 0xC00000 + i
    local val = mem:read_u8(addr)
    if val ~= 0 then
        gvram_hits = gvram_hits + 1
    end
end
print(string.format("GVRAM non-zero bytes: %d", gvram_hits))
```

#### Issue 2: IOCS Drawing Functions Crash

**Symptom:** `_LINE` (0x81), `_BOX` (0x82), `_CIRCLE` (0x88) cause "Illegal instruction"
errors, while `_PSET` (0x80) and `_FILL` (0x87) execute without error.

**Possible causes:**
- Parameter format mismatch (word vs long, line style parameter issues)
- IOCS version differences between real hardware and MAME
- Function requires additional setup (color palette, line style table)

**Workaround:** Use _PSET and _FILL only. Avoid _LINE, _BOX, _CIRCLE until parameter
format is better understood.

#### Issue 3: Graphics Mode Register Shows Unexpected Value

**Symptom:** After IOCS _CRTMOD(4), reading 0xE82500 returns 0x06E4 instead of 0x0000
or mode 4 indicator.

**Analysis:** Graphics mode register format is not well documented. The value 0x06E4
may be a composite of resolution, color depth, and other flags rather than a simple
mode number. This does not appear to cause functional issues.

### Best Practices for Graphics Programming

1. **Always call IOCS graphics functions BEFORE entering supervisor mode**
   - IOCS calls can be made from user mode
   - Entering supervisor mode first may interfere with IOCS state

2. **Use IOCS for screen mode switching, manual register writes for sprite setup**
   - _CRTMOD, _G_CLR_ON, _VPAGE are reliable for graphics initialization
   - Direct hardware access needed for sprite control (no IOCS sprite functions)

3. **Wait for VSync before updating sprite positions or patterns**
   - Prevents tearing and flickering
   - Use IOCS _VSYNC (0x12) or poll bit 4 of 0xE88001

4. **Keep programs running to preserve graphics output**
   - Exiting returns to text mode and clears graphics
   - Use infinite loop with optional keyboard check for exit

5. **Test graphics initialization without supervisor mode first**
   - Verify IOCS calls work correctly in user mode
   - Add supervisor mode only when accessing sprite/palette hardware directly

6. **Use automated screenshot testing for visual verification**
   ```bash
   make test-auto  # Captures screenshot to ~/.mame/snap/
   ```

7. **Diagnostic memory dumps in Lua scripts**
   - Check VIDEO_CTRL, palette RAM, PCG RAM, sprite control
   - Verify data is written where expected before debugging visibility

## Common Failure Modes and Diagnostics

### "Illegal instruction executed (PC=$xxxxxxxx)"
**Cause:** Position-dependency bug. Code has absolute addresses but was loaded at a
different address than expected.

**Check:**
1. `xxd build/bin/helloc.x | head -4` → verify `base_address` at offset 0x04 is `00 00 00 00`
2. `m68k-linux-gnu-objdump -d build/bin/helloc.elf | grep -E "pea|jsr|lea"` → verify all PC-relative

**Fix:** Add `-mpcrel` to CFLAGS, ensure `crt0.s` uses `jsr main(%pc)` not `jsr main`.

### "Bus error has occurred (PC=$00FFxxxx)"
**Cause:** Memory corruption, often from forcing `base_address = 0x6800` when that
region is already occupied by the shell.

**Fix:** Set `base_address = 0` in `make_xfile.py`, rely on PIC code.

### "TEST PARTIAL — program loaded but no screen output"
**Cause:** TVRAM scan only checks the first 256 cells; text has scrolled beyond that range.

**Fix:** Increase TVRAM scan range or use stride sampling across the full 32 KB plane.

### MAME hangs at warning screen (PC stays in BIOS)
**Cause:** Warning dismissal failed (cfg patch didn't apply, XTEST click missed).

**Fix:**
1. Verify `~/.mame/cfg/x68000.cfg` exists and has `warned="9999999999"`
2. Check `xdotool search --pid $MAME_PID` finds the window
3. Increase sleep before click (screen render delay)
4. Verify DISPLAY is set (xdotool needs X11)

### "No such file or directory" or missing symbols
**Cause:** Build order issue (crt0.o not compiled before linking).

**Fix:** Ensure Makefile dependencies are correct:
```makefile
$(BINDIR)/helloc.elf: $(OBJDIR)/crt0.o $(OBJDIR)/helloc.o x68k.ld | $(BINDIR)
```

## File Structure

```
x68000dev/
├── src/
│   ├── hello.s          — Assembly hello world (VASM, PC-relative)
│   ├── helloc.c         — C hello world (inline F-line asm)
│   └── crt0.s           — C runtime startup (_start → main → _EXIT)
├── build/
│   ├── obj/             — Intermediate .o files
│   └── bin/             — Final .x executables, .elf, .bin
├── tools/
│   ├── vasmm68k_mot     — VASM assembler
│   ├── make_xfile.py    — .X header wrapper (64 bytes + payload)
│   ├── test.sh          — Interactive MAME launcher
│   └── test_gui_automated.sh — Fully automated test + validation
├── mame/
│   └── test_hello.lua   — MAME Lua validator (TVRAM scan, pass/fail)
├── tests/
│   └── autoexec_test.bat — Human68k batch file for automated runs
├── Makefile             — Builds both assembly and C programs
├── x68k.ld              — Linker script (entry _start, origin 0x6800)
└── MasterDisk_V3.xdf    — X68000 boot floppy image (FAT12)
```

## Essential Commands

### Build
```bash
make all        # Build both programs
make clean      # Remove build artifacts
make install    # Copy to boot disk (::PROGRAM.X, ::HELLOC.X)
```

### Test
```bash
make test       # Interactive MAME (manual execution at A> prompt)
make test-auto  # Fully automated (AUTOEXEC.BAT → Lua validation → exit)
```

### Inspect
```bash
# Verify .X header
xxd build/bin/helloc.x | head -5

# Check for position-independent code
m68k-linux-gnu-objdump -d build/bin/helloc.elf | grep -E "pea|jsr|lea"

# List boot disk contents
mdir -i MasterDisk_V3.xdf ::

# Manually copy files
mcopy -i MasterDisk_V3.xdf -o build/bin/helloc.x ::HELLOC.X
```

## Porting to Other Platforms

This test harness pattern can be adapted for other retro systems:

### Universal Principles
1. **Separate build paths** — one for native assemblers (if available), one for GCC cross-compilation
2. **Position-independent code** — use PC-relative addressing or relocation tables
3. **Minimal C runtime** — bare `_start` that calls `main()` then exits via syscall
4. **Header wrapper** — script to prepend platform-specific executable headers
5. **Automated validation** — emulator Lua scripting to check RAM/VRAM for expected output
6. **Dual warning dismissal** — config pre-patch + fallback UI automation

### Platform-Specific Adaptations
- **Commodore Amiga** — GCC m68k, similar workflow but Amiga Hunk format instead of `.X`
- **Atari ST** — m68k GCC, TOS `.TTP`/`.PRG` format, GEMDOS syscalls via TRAP #1
- **PC-98** — i86/i386 GCC, DOS `.COM`/`.EXE` format, INT 21h syscalls
- **FM Towns** — i386 GCC, Towns OS format, different syscall mechanism

Replace Human68k F-line handlers with the target OS's syscall convention (TRAP #n,
software interrupt, or direct BIOS calls). Adjust memory map and header format.

## References

### X68000 Documentation
- Human68k system call reference (F-line opcodes)
- X68000 memory map and I/O registers
- IOCS (hardware BIOS) vs DOS (software syscalls) distinction

### Toolchain
- VASM documentation: http://sun.hasenbraten.de/vasm/
- GCC m68k options: `-m68000`, `-mpcrel`, `-nostdlib`, etc.
- MAME Lua API: memory access, screen capture, timer events

### Debugging
- MAME debugger: `-debug` flag, breakpoints, memory inspection
- GDB remote debugging: MAME gdbstub support
- objdump for disassembly verification

## Example: Adding a New Program

```bash
# 1. Create source
cat > src/newprog.c <<'EOF'
void dos_print(const char *msg) {
    __asm__ __volatile__(
        "pea (%0)\n\t"
        ".word 0xff09\n\t"
        "addq.l #4, %%sp"
        : : "a" (msg) : "memory"
    );
}

void main(void) {
    dos_print("My new program!\r\n");
}
EOF

# 2. Add to Makefile
# Define NEWPROG variable:
NEWPROG = $(BINDIR)/newprog.x

# Add to 'all' target:
all: $(PROGRAM) $(HELLOC) $(NEWPROG)

# Add build rules:
$(OBJDIR)/newprog.o: src/newprog.c | $(OBJDIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BINDIR)/newprog.elf: $(OBJDIR)/crt0.o $(OBJDIR)/newprog.o x68k.ld | $(BINDIR)
	$(LD) -T x68k.ld -o $@ $(OBJDIR)/crt0.o $(OBJDIR)/newprog.o

$(BINDIR)/newprog.bin: $(BINDIR)/newprog.elf
	$(OBJCOPY) -O binary $< $@

$(NEWPROG): $(BINDIR)/newprog.bin tools/make_xfile.py
	python3 tools/make_xfile.py $< $@

# 3. Build and test
make clean && make all
mcopy -i MasterDisk_V3.xdf -o build/bin/newprog.x ::NEWPROG.X
make test  # At A> prompt: A:NEWPROG.X
```

## Testing Checklist

Before pushing changes:
- [ ] `make clean && make all` succeeds
- [ ] `xxd build/bin/*.x | head -4` shows correct `.X` magic (HU) and base=0
- [ ] `m68k-linux-gnu-objdump -d` shows PC-relative addressing (no absolute `$xxxx`)
- [ ] `make test-auto` reports `TEST PASSED` with TVRAM hits > 0
- [ ] Screenshot (`~/.mame/snap/hello_result.png`) shows expected output
- [ ] No "illegal instruction" or "bus error" dialogs on screen
