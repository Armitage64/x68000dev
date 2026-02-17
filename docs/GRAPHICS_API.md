# X68000 Graphics Programming Reference

Comprehensive guide to X68000 graphics programming for game development.

## Graphics Hardware Overview

The X68000 has sophisticated 2D graphics hardware:

- **Resolution:** Up to 768×512 pixels
- **Colors:** Up to 65,536 simultaneous colors
- **Layers:** Multiple graphics planes
- **Sprites:** Hardware sprites with transparency
- **Scrolling:** Hardware scrolling support
- **Special Effects:** Raster effects, transparency

## Memory Map

### Graphics VRAM

```
0x00C00000 - Graphics VRAM plane 0
0x00C20000 - Graphics VRAM plane 1
0x00C40000 - Graphics VRAM plane 2
0x00C60000 - Graphics VRAM plane 3
```

### Text VRAM

```
0x00E00000 - Text plane
0x00E20000 - Text attributes
```

### Control Registers

```
0x00E80000 - CRTC (CRT Controller)
0x00E82000 - Video control
0x00E82500 - Graphics mode
0x00EB0000 - Sprite control
```

## Graphics Modes

### Setting Graphics Mode

```c
#define GFX_CTRL ((volatile unsigned short *)0xE82500)

void set_graphics_mode(int mode) {
    *GFX_CTRL = mode;
}
```

### Common Modes

```c
// 16-color mode (4 bitplanes)
set_graphics_mode(0x0000);

// 256-color mode (1 byte per pixel)
set_graphics_mode(0x0004);

// 65,536-color mode (2 bytes per pixel)
set_graphics_mode(0x0014);
```

## Palette Control

### Setting Palette Colors

The X68000 uses a color palette for graphics modes below 65K colors.

```c
#define PALETTE_BASE ((volatile unsigned short *)0xE82000)

void set_palette(int index, unsigned short rgb) {
    PALETTE_BASE[index] = rgb;
}

// RGB format: GGGGGRRRRRBBBBB (5-5-5)
// Example: Pure red
set_palette(1, 0x07C00);  // Red = 11111, Green = 0, Blue = 0

// Pure green
set_palette(2, 0x003E0);  // Green = 11111

// Pure blue
set_palette(3, 0x0001F);  // Blue = 11111

// White
set_palette(15, 0x07FFF);
```

### RGB Macro

```c
#define RGB(r, g, b) (((g) << 10) | ((r) << 5) | (b))

// Usage
set_palette(4, RGB(31, 15, 0));  // Orange
```

## Drawing Functions

### Direct Pixel Access

```c
#define GVRAM ((volatile unsigned short *)0xC00000)
#define SCREEN_WIDTH 512

void set_pixel(int x, int y, unsigned char color) {
    GVRAM[y * SCREEN_WIDTH + x] = color;
}

unsigned char get_pixel(int x, int y) {
    return GVRAM[y * SCREEN_WIDTH + x];
}
```

### Line Drawing

```c
void draw_line(int x1, int y1, int x2, int y2, unsigned char color) {
    int dx = x2 - x1;
    int dy = y2 - y1;
    int steps = (dx > dy) ? dx : dy;

    if (steps < 0) steps = -steps;

    float x_inc = (float)dx / steps;
    float y_inc = (float)dy / steps;

    float x = x1;
    float y = y1;

    for (int i = 0; i <= steps; i++) {
        set_pixel((int)x, (int)y, color);
        x += x_inc;
        y += y_inc;
    }
}
```

### Rectangle Drawing

```c
// Filled rectangle
void fill_rect(int x, int y, int w, int h, unsigned char color) {
    volatile unsigned short *vram = GVRAM;
    for (int py = y; py < y + h; py++) {
        for (int px = x; px < x + w; px++) {
            vram[py * SCREEN_WIDTH + px] = color;
        }
    }
}

// Outlined rectangle
void draw_rect(int x, int y, int w, int h, unsigned char color) {
    draw_line(x, y, x + w, y, color);           // Top
    draw_line(x, y + h, x + w, y + h, color);   // Bottom
    draw_line(x, y, x, y + h, color);           // Left
    draw_line(x + w, y, x + w, y + h, color);   // Right
}
```

### Circle Drawing

```c
void draw_circle(int cx, int cy, int radius, unsigned char color) {
    int x = 0;
    int y = radius;
    int d = 3 - 2 * radius;

    while (x <= y) {
        set_pixel(cx + x, cy + y, color);
        set_pixel(cx - x, cy + y, color);
        set_pixel(cx + x, cy - y, color);
        set_pixel(cx - x, cy - y, color);
        set_pixel(cx + y, cy + x, color);
        set_pixel(cx - y, cy + x, color);
        set_pixel(cx + y, cy - x, color);
        set_pixel(cx - y, cy - x, color);

        if (d < 0) {
            d = d + 4 * x + 6;
        } else {
            d = d + 4 * (x - y) + 10;
            y--;
        }
        x++;
    }
}
```

## Sprite System

### Hardware Sprites

The X68000 has hardware sprites (PCG - Programmable Character Generator).

```c
#define SPRITE_REG_BASE ((volatile unsigned short *)0xEB0000)
#define SPRITE_DATA_BASE ((volatile unsigned short *)0xEB8000)

struct sprite {
    unsigned short ctrl;
    unsigned short x;
    unsigned short y;
    unsigned short pattern;
};

void set_sprite(int sprite_num, int x, int y, int pattern) {
    volatile struct sprite *spr = (volatile struct sprite *)(SPRITE_REG_BASE + sprite_num * 4);
    spr->x = x;
    spr->y = y;
    spr->pattern = pattern;
    spr->ctrl = 0x0001;  // Enable sprite
}

void hide_sprite(int sprite_num) {
    volatile struct sprite *spr = (volatile struct sprite *)(SPRITE_REG_BASE + sprite_num * 4);
    spr->ctrl = 0x0000;  // Disable sprite
}
```

### Loading Sprite Data

```c
void load_sprite_pattern(int pattern_num, const unsigned short *data, int width, int height) {
    volatile unsigned short *sprite_data = SPRITE_DATA_BASE + (pattern_num * 16 * 16);

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            sprite_data[y * 16 + x] = data[y * width + x];
        }
    }
}
```

## Double Buffering

For smooth animation, use double buffering:

```c
#define BUFFER_SIZE (512 * 512)
unsigned short back_buffer[BUFFER_SIZE];

void clear_buffer(unsigned char color) {
    for (int i = 0; i < BUFFER_SIZE; i++) {
        back_buffer[i] = color;
    }
}

void swap_buffers() {
    volatile unsigned short *vram = GVRAM;
    for (int i = 0; i < BUFFER_SIZE; i++) {
        vram[i] = back_buffer[i];
    }
}

// Usage
clear_buffer(0);
// Draw to back_buffer...
swap_buffers();
```

## Scrolling

### Hardware Scrolling

```c
#define SCROLL_X_REG ((volatile unsigned short *)0xE80000)
#define SCROLL_Y_REG ((volatile unsigned short *)0xE80002)

void set_scroll(int x, int y) {
    *SCROLL_X_REG = x;
    *SCROLL_Y_REG = y;
}

// Smooth scrolling example
void scroll_animation() {
    for (int x = 0; x < 256; x++) {
        set_scroll(x, 0);
        vsync_wait();  // Wait for vertical sync
    }
}
```

## VSync and Timing

### Wait for Vertical Blank

```c
#define VSYNC_REG ((volatile unsigned char *)0xE88001)

void vsync_wait() {
    // Wait for VSync
    while (*VSYNC_REG & 0x10);
    while (!(*VSYNC_REG & 0x10));
}
```

### Frame Rate Control

```c
void game_loop() {
    while (1) {
        vsync_wait();

        // Update game logic
        update_game();

        // Render
        render_frame();
    }
}
```

## Text Rendering

### Basic Text

```c
#define TEXT_VRAM ((volatile unsigned short *)0xE00000)
#define TEXT_WIDTH 128

void put_char(int x, int y, char ch) {
    TEXT_VRAM[y * TEXT_WIDTH + x] = ch;
}

void print_string(int x, int y, const char *str) {
    int i = 0;
    while (str[i]) {
        put_char(x + i, y, str[i]);
        i++;
    }
}
```

### Colored Text

```c
#define TEXT_ATTR ((volatile unsigned short *)0xE20000)

void set_text_color(int x, int y, unsigned char fg, unsigned char bg) {
    TEXT_ATTR[y * TEXT_WIDTH + x] = (bg << 8) | fg;
}
```

## Bitmap Graphics

### Loading Images

```c
void draw_bitmap(int x, int y, int w, int h, const unsigned char *bitmap) {
    volatile unsigned short *vram = GVRAM;

    for (int py = 0; py < h; py++) {
        for (int px = 0; px < w; px++) {
            vram[(y + py) * SCREEN_WIDTH + (x + px)] = bitmap[py * w + px];
        }
    }
}
```

### Transparency

```c
#define TRANSPARENT_COLOR 0

void draw_bitmap_transparent(int x, int y, int w, int h, const unsigned char *bitmap) {
    volatile unsigned short *vram = GVRAM;

    for (int py = 0; py < h; py++) {
        for (int px = 0; px < w; px++) {
            unsigned char color = bitmap[py * w + px];
            if (color != TRANSPARENT_COLOR) {
                vram[(y + py) * SCREEN_WIDTH + (x + px)] = color;
            }
        }
    }
}
```

## Performance Tips

### 1. Minimize VRAM Access

```c
// Slow - writes to VRAM in loop
for (int i = 0; i < 1000; i++) {
    GVRAM[i] = color;
}

// Faster - batch writes
volatile unsigned short *vram = GVRAM;
for (int i = 0; i < 1000; i++) {
    vram[i] = color;
}
```

### 2. Use Hardware Features

- Hardware sprites instead of software blitting
- Hardware scrolling instead of redrawing
- Palette animation instead of redrawing

### 3. Dirty Rectangle Rendering

```c
// Only redraw changed areas
void update_dirty_rect(int x, int y, int w, int h) {
    // Redraw only this rectangle
}
```

### 4. Fixed-Point Math

```c
// Avoid floating-point, use fixed-point
typedef int fixed;
#define FIXED_SHIFT 8
#define TO_FIXED(x) ((x) << FIXED_SHIFT)
#define FROM_FIXED(x) ((x) >> FIXED_SHIFT)

fixed pos_x = TO_FIXED(100);
pos_x += TO_FIXED(5) / 2;  // Add 2.5
int screen_x = FROM_FIXED(pos_x);
```

## Common Graphics Patterns

### Game Background

```c
void draw_background() {
    // Fill with base color
    fill_rect(0, 0, 512, 512, 1);

    // Add details
    for (int i = 0; i < 10; i++) {
        fill_rect(i * 50, 100, 40, 40, 2);
    }
}
```

### Simple Animation

```c
struct animated_sprite {
    int x, y;
    int frame;
    int frame_count;
};

void animate_sprite(struct animated_sprite *spr) {
    spr->frame = (spr->frame + 1) % spr->frame_count;
    set_sprite(0, spr->x, spr->y, spr->frame);
}
```

### Particle System

```c
struct particle {
    int x, y;
    int vx, vy;
    unsigned char color;
    int life;
};

void update_particles(struct particle *particles, int count) {
    for (int i = 0; i < count; i++) {
        if (particles[i].life > 0) {
            particles[i].x += particles[i].vx;
            particles[i].y += particles[i].vy;
            particles[i].life--;
            set_pixel(particles[i].x, particles[i].y, particles[i].color);
        }
    }
}
```

## Example: Complete Drawing System

```c
typedef struct {
    volatile unsigned short *vram;
    int width;
    int height;
    unsigned char draw_color;
} graphics_context;

graphics_context gfx;

void init_graphics() {
    // Enter supervisor mode
    asm volatile (
        "move.l #0xFFFFFFFF, %%d0\n"
        "trap   #15\n"
        "dc.w   0xFF30\n"
        : : : "d0", "d1", "a0", "a1"
    );

    // Set 256-color mode
    set_graphics_mode(0x0004);

    // Initialize context
    gfx.vram = GVRAM;
    gfx.width = 512;
    gfx.height = 512;
    gfx.draw_color = 255;

    // Clear screen
    fill_rect(0, 0, 512, 512, 0);
}

void set_color(unsigned char color) {
    gfx.draw_color = color;
}

void plot(int x, int y) {
    if (x >= 0 && x < gfx.width && y >= 0 && y < gfx.height) {
        gfx.vram[y * gfx.width + x] = gfx.draw_color;
    }
}
```

## Next Steps

- Study the example program in `src/main.c`
- Experiment with colors and shapes
- Try implementing a simple game
- Read X68000 technical manuals for advanced features
- Join the X68000 development community!

## Further Reading

- X68000 Technical Manual (Japanese)
- MAME source code (x68k driver)
- Existing X68000 games (study techniques)
- Motorola 68000 reference manual
