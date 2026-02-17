# X68000 Programming Guide for Beginners

A beginner-friendly introduction to Sharp X68000 programming.

## What is the Sharp X68000?

The Sharp X68000 (エックス ろくまんはっせん) was a Japanese home computer released in 1987. It was designed for arcade-perfect game ports and creative applications.

### Hardware Specifications

- **CPU:** Motorola 68000 @ 10 MHz (16/32-bit)
- **RAM:** 1-4 MB (expandable)
- **Graphics:** Custom video chips
  - 768×512 resolution
  - 65,536 colors
  - Sprites, scrolling, multiple layers
- **Sound:** YM2151 (OPM), ADPCM
- **OS:** Human68k (DOS-like operating system)

### Why Develop for X68000 in 2024?

- **Learning:** Great platform to learn 68000 assembly and low-level programming
- **Retro gaming:** Create games for a beloved system
- **Emulation:** Accurate emulation available (MAME, XM6)
- **Community:** Active retro computing community
- **Fun:** It's a joy to program close to the hardware!

## Motorola 68000 CPU Basics

### Registers

The 68000 has 16 registers:

**Data Registers (D0-D7):**
- General-purpose data storage
- 32-bit wide
- Used for calculations, temporary storage

**Address Registers (A0-A6):**
- Store memory addresses (pointers)
- Used for array access, structures
- 32-bit wide

**Stack Pointer (A7/SP):**
- Points to the stack
- Used for function calls, local variables

**Program Counter (PC):**
- Points to the current instruction
- Automatically incremented

**Status Register (SR):**
- CPU flags (zero, carry, negative, etc.)
- Supervisor/user mode bit
- Interrupt mask

### Addressing Modes

```assembly
move.l  d0, d1              # Register direct
move.l  #100, d0            # Immediate
move.l  (a0), d0            # Address register indirect
move.l  (a0)+, d0           # Post-increment
move.l  -(a0), d0           # Pre-decrement
move.l  10(a0), d0          # Displacement
move.l  $1000, d0           # Absolute
```

### Common Instructions

```assembly
move.l  d0, d1              # Move (copy) data
add.l   d0, d1              # Add (d1 = d1 + d0)
sub.l   d0, d1              # Subtract
and.l   d0, d1              # Bitwise AND
or.l    d0, d1              # Bitwise OR
cmp.l   d0, d1              # Compare
jmp     label               # Jump
jsr     subroutine          # Jump to subroutine
rts                         # Return from subroutine
bra     label               # Branch always
beq     label               # Branch if equal
bne     label               # Branch if not equal
```

### Data Sizes

```assembly
move.b  d0, d1              # Byte (8-bit)
move.w  d0, d1              # Word (16-bit)
move.l  d0, d1              # Long (32-bit)
```

## Human68k Operating System

Human68k is a DOS-like OS that came with the X68000.

### Program Structure

Human68k programs (`.X` files) are loaded at address `0x6800` with:
- Stack already set up
- OS available via system calls
- Can return to OS with DOS call

### System Calls

**DOS Calls (TRAP #15):**

```assembly
# Exit program
move.w  #0xFF00, d0
trap    #15
dc.w    0xFF00
```

**IOCS Calls (TRAP #15):**

IOCS = Input/Output Control System

```assembly
# Enter supervisor mode
move.l  #0xFFFFFFFF, d0
trap    #15
dc.w    0xFF30
```

Common IOCS functions:
- `0xFF00` - EXIT (exit to DOS)
- `0xFF30` - B_SUPER (supervisor mode)
- `0xFF40` - B_PUTC (print character)
- `0xFF50` - B_PRINT (print string)

## Memory Map

### Physical Memory Layout

```
0x00000000 - 0x00BFFFFF : ROM (BIOS, system)
0x00C00000 - 0x00FFFFFF : Main RAM (up to 4MB)
0x00E00000 - 0x00E7FFFF : Text VRAM
0x00E80000 - 0x00EBFFFF : I/O and control registers
0x00C00000 - 0x00EFFFFF : Graphics VRAM
```

### Important Addresses

```c
// Graphics
#define GVRAM       0xC00000    // Graphics VRAM
#define TEXT_VRAM   0xE00000    // Text VRAM
#define CRTC_REG    0xE80000    // CRTC registers
#define GFX_CTRL    0xE82500    // Graphics control

// System
#define MAIN_RAM    0x00C00000  // Start of main RAM

// I/O
#define KEYBOARD    0xE90000    // Keyboard
#define MOUSE       0xE98000    // Mouse
#define TIMER       0xE88000    // Timer
```

## Writing Your First Program

### Minimal Program (Assembly)

```assembly
    .text
    .globl _start

_start:
    # Your code here

    # Exit to Human68k
    move.w  #0xFF00, d0
    trap    #15
    dc.w    0xFF00
```

### Minimal Program (C)

```c
void main() {
    // Your code here
}

// Startup code in start.s handles entry and exit
```

### Startup Code

Our `src/start.s` provides:
- Program entry point (`_start`)
- Stack setup
- Call to C `main()`
- Clean exit to Human68k

## Graphics Programming Basics

### Supervisor Mode

Hardware access requires supervisor mode:

```c
void enter_supervisor() {
    asm volatile (
        "move.l #0xFFFFFFFF, %%d0\n"
        "trap   #15\n"
        "dc.w   0xFF30\n"
        : : : "d0", "d1", "a0", "a1"
    );
}
```

### Graphics Modes

The X68000 has several graphics modes:

```c
// Set 256-color mode
*(volatile unsigned short *)0xE82500 = 0x0004;
```

Common modes:
- 16 colors (4 bitplanes)
- 256 colors (8-bit)
- 65,536 colors (16-bit)

### Drawing Pixels

```c
void set_pixel(int x, int y, unsigned char color) {
    volatile unsigned short *vram = (volatile unsigned short *)0xC00000;
    vram[y * 512 + x] = color;
}
```

### Drawing Rectangles

```c
void draw_rect(int x, int y, int w, int h, unsigned char color) {
    volatile unsigned short *vram = (volatile unsigned short *)0xC00000;
    for (int py = y; py < y + h; py++) {
        for (int px = x; px < x + w; px++) {
            vram[py * 512 + px] = color;
        }
    }
}
```

## Text Display

### Text VRAM

Text is displayed in a separate VRAM area:

```c
void print_text(const char *str, int x, int y) {
    volatile unsigned short *text_vram = (volatile unsigned short *)0xE00000;
    int i = 0;
    while (str[i]) {
        text_vram[y * 128 + x + i] = str[i];
        i++;
    }
}
```

## Input Handling

### Keyboard

```c
unsigned char read_keyboard() {
    volatile unsigned char *keyboard = (volatile unsigned char *)0xE90000;
    return *keyboard;
}
```

### Mouse

```c
struct mouse_state {
    short x, y;
    unsigned char buttons;
};

void read_mouse(struct mouse_state *state) {
    volatile unsigned char *mouse = (volatile unsigned char *)0xE98000;
    // Read mouse data (simplified)
    state->x = mouse[0];
    state->y = mouse[1];
    state->buttons = mouse[2];
}
```

## Sound Basics

The X68000 has multiple sound chips:

### YM2151 (OPM)

FM synthesis sound chip (8 channels):

```c
#define OPM_ADDR    0xE90001
#define OPM_DATA    0xE90003

void opm_write(unsigned char reg, unsigned char data) {
    volatile unsigned char *opm_addr = (volatile unsigned char *)OPM_ADDR;
    volatile unsigned char *opm_data = (volatile unsigned char *)OPM_DATA;
    *opm_addr = reg;
    *opm_data = data;
}
```

### MXDRV.X

MXDRV is a popular music driver for X68000. You can play MDX music files with it.

## Best Practices

### 1. Use Volatile for Hardware Access

```c
volatile unsigned short *vram = (volatile unsigned short *)0xC00000;
```

The `volatile` keyword prevents the compiler from optimizing away hardware accesses.

### 2. Check Alignment

The 68000 requires 16-bit and 32-bit accesses to be aligned:

```c
// Good - aligned to 2-byte boundary
unsigned short value = *(unsigned short *)0xC00000;

// Bad - may crash on odd address
unsigned short value = *(unsigned short *)0xC00001;
```

### 3. Minimize VRAM Writes

Graphics VRAM is slower than RAM. Buffer in RAM when possible:

```c
unsigned short buffer[512*512];
// Draw to buffer
// ...
// Copy to VRAM at once
memcpy((void *)0xC00000, buffer, sizeof(buffer));
```

### 4. Use Hardware Features

The X68000 has hardware sprites, scrolling, etc. Use them instead of software rendering when possible.

## Common Pitfalls

### Forgetting Supervisor Mode

```c
// This will fail without supervisor mode!
*(volatile unsigned short *)0xE82500 = 0x0004;
```

Always enter supervisor mode before hardware access.

### Wrong Memory Addresses

Double-check addresses in the manual. Typos cause crashes!

### Infinite Loops Without Wait

```c
// Bad - burns CPU
while (1) {}

// Better - includes delay
while (1) {
    asm volatile ("nop");
}
```

### Not Returning to Human68k

Always exit cleanly:

```assembly
move.w  #0xFF00, d0
trap    #15
dc.w    0xFF00
```

## Learning Resources

### Books

- "X68000 Programming Manual" (Japanese)
- "Inside X68000" (Japanese)
- "Motorola 68000 Programmer's Reference Manual"

### Online

- MAME documentation
- X68000 communities (forums, Discord)
- 68000 assembly tutorials
- This repository's examples!

### Practice Projects

1. **Hello World** - Print text to screen
2. **Pixel Art** - Draw shapes and patterns
3. **Animation** - Move sprites around
4. **Input** - Respond to keyboard/mouse
5. **Sound** - Play a simple tone
6. **Game** - Combine everything!

## Next Steps

- Read [GRAPHICS_API.md](GRAPHICS_API.md) - Detailed graphics programming
- Study the example program in `src/main.c`
- Experiment with modifying the example
- Join X68000 communities
- Have fun and ask questions!

## X68000 Development Philosophy

The X68000 was designed to be programmer-friendly:
- Direct hardware access
- Powerful graphics capabilities
- Good documentation (in Japanese)
- Active homebrew community

Embrace the constraints and have fun programming close to the metal!
