/*
 * Minimal MXDRV test - just check if MXDRV responds
 */
#include <stdio.h>

extern int mxdrv_call(int func);

int main(void) {
    int result;

    printf("MXDRV Minimal Test\r\n");
    printf("==================\r\n\r\n");

    printf("Calling MXDRV_STAT (function 2)...\r\n");
    result = mxdrv_call(2);

    printf("Result: %d (0x%04x)\r\n", result, result & 0xFFFF);

    if (result >= 0) {
        printf("\r\nSUCCESS! MXDRV is responding.\r\n");
    } else {
        printf("\r\nFAILED! MXDRV returned error.\r\n");
    }

    return 0;
}
