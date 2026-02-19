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
