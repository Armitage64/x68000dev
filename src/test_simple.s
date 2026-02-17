# Minimal Human68k executable test
# Based on working Human68k programs

    .text

    # Program starts here (loaded at 0x6800)
    # Fill GVRAM with visible pattern
    movea.l #0xC00000, %a0
    move.w  #2000, %d0

loop:
    move.w  %d0, (%a0)+
    subq.w  #1, %d0
    bne.s   loop

    # Exit to Human68k
    move.w  #0xFF00, %d0
    trap    #15
    .word   0xFF00

    # End marker
    .end
