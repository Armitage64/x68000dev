/* X68000 Linker Script for Human68k Executables
 *
 * Human68k loads programs at address 0x00006800
 * This linker script defines the memory layout for X68000 programs
 */

OUTPUT_ARCH(m68k)
ENTRY(_start)

MEMORY
{
    /* Human68k loads programs at 0x00006800 */
    ram : ORIGIN = 0x00006800, LENGTH = 1M
}

SECTIONS
{
    .text 0x00006800 : {
        *(.text.startup)
        *(.text)
        *(.text.*)
    } > ram

    .rodata : {
        *(.rodata)
        *(.rodata.*)
    } > ram

    .data : {
        *(.data)
        *(.data.*)
    } > ram

    .bss : {
        *(.bss)
        *(.bss.*)
        *(COMMON)
    } > ram
}
