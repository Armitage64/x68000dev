/*
 * Simple X68000 Test Program
 * Just fills GVRAM to test execution
 */

void main() {
    volatile unsigned short *vram = (volatile unsigned short *)0xC00000;
    int i;

    // Fill first 1000 words of GVRAM with a pattern
    for (i = 0; i < 1000; i++) {
        vram[i] = 0xFF00 + (i & 0xFF);
    }

    // Infinite loop
    while(1) {
        __asm__ volatile ("nop");
    }
}
