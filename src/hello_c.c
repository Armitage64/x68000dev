/* Hello World in C for X68000 / Human68k
 * DOS services are invoked via F-line opcodes (dc.w 0xFFxx).
 * _PRINT (0xFF09): pointer to null-terminated string on stack.
 * _EXIT  (0xFF00): terminate process.
 */

static void dos_print(const char *msg) {
    __asm__ __volatile__(
        "pea (%0)\n\t"          /* push string address */
        ".word 0xff09\n\t"      /* DOS _PRINT (F-line opcode) */
        "addq.l #4, %%sp"       /* pop 4-byte argument */
        :
        : "a" (msg)             /* 'a' = address register constraint */
        : "memory"
    );
}

void main(void) {
    dos_print("Hello from C on X68000!\r\n");
}
