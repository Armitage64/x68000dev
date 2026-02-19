/* crt0.s - Minimal startup for Human68k C programs
 * Assembled by m68k-linux-gnu-as; GAS m68k syntax (% register prefixes).
 */
    .global _start
    .text
_start:
    jsr     main(%pc)   /* PC-relative call to main — position independent */
    .word   0xFF00      /* DOS _EXIT (F-line opcode) */
