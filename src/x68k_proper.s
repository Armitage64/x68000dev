# Proper Human68k .X executable with header
# Based on Human68k executable specification

    .text

# X file header (must be first)
x_header:
    # "HU" - executable marker
    .word   0x4855
    # "MA"
    .word   0x4D41
    # Size of text segment
    .long   text_size
    # Size of data segment
    .long   0
    # Size of BSS segment
    .long   0
    # Size of relocation table
    .long   0
    # Symbol table (not used)
    .long   0
    # Reserved
    .long   0
    # Entry point offset
    .long   entry
    # Reserved
    .long   0

text_start:
entry:
    # Our actual program code
    movea.l #0xC00000, %a0
    move.w  #2000, %d0

fill:
    move.w  %d0, (%a0)+
    subq.w  #1, %d0
    bne.s   fill

    # Exit
    move.w  #0xFF00, %d0
    trap    #15
    .word   0xFF00

text_end:
    .set text_size, text_end - text_start
