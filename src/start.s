# Human68k .X Executable Header
# Proper format for X68000 executables

    .text
    .globl _start

# Human68k .X file header
# Simple format: starts with BRA to actual code
_start:
    # Branch to actual program start
    bra.w   program_start

    # Minimal header info (Human68k expects this)
    .ascii  "Human68k"
    .align  2

program_start:
    # Save original stack pointer
    move.l  %sp, %a5

    # Set up our own stack
    lea     stack_top, %sp

    # Call main
    jsr     main

    # Exit to Human68k
    move.w  #0xFF00, %d0
    trap    #15
    dc.w    0xFF00

    # Should never reach here
    illegal

    # Stack space (1KB)
    .section .bss
    .align  4
stack_bottom:
    .space  1024
stack_top:
