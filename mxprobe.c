/*
 * MXDRV30.X Function Probe
 * Test multiple MXDRV functions to see what works
 */
#include <stdio.h>

extern int mxdrv_call(int func);
extern int mxdrv_get_work_ptr(void);

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
        result = mxdrv_call(i);
        printf("0x%08lx (%ld)\r\n", (unsigned long)result, (long)result);
    }

    printf("\r\nTrying mxdrv_get_work_ptr()...\r\n");
    result = mxdrv_get_work_ptr();
    printf("Work ptr: 0x%08lx\r\n", (unsigned long)result);

    return 0;
}
