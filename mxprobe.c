/*
 * MXDRV30.X Function Probe
 * Test multiple MXDRV functions to see what works
 * Filename: mxprobe.c (no underscores for X68000 keyboard)
 */
#include <stdio.h>

extern int mxdrvcall(int func);
extern int mxdrvwork(void);

int main(void) {
    int i, result;

    printf("MXDRV30.X Function Probe\r\n");
    printf("========================\r\n\r\n");

    /* Try functions 0, 2-10 (skip 1 - it causes errors) */
    for (i = 0; i <= 10; i++) {
        if (i == 1) {
            printf("Function %2d: (skipped - causes error)\r\n", i);
            continue;
        }
        printf("Function %2d: ", i);
        result = mxdrvcall(i);
        printf("0x%08lx (%ld)\r\n", (unsigned long)result, (long)result);
    }

    printf("\r\nTrying mxdrvwork()...\r\n");
    result = mxdrvwork();
    printf("Work ptr: 0x%08lx\r\n", (unsigned long)result);

    return 0;
}
