# GDB Debugging Script for X68000 Development
# Connect to MAME's GDB stub for source-level debugging

# Connect to MAME GDB stub
target remote localhost:1234

# Set architecture
set architecture m68k

# Load symbols from ELF file (before objcopy)
file build/bin/helloa.x.elf

# Common breakpoints for X68000
# Break at program start
break _start

# Break at main
break main

# Custom command to display registers and code
define show_regs
    info registers
    x/8i $pc
end

# Display initial state
show_regs

# Continue execution
echo Ready to debug. Use 'continue' to start execution.\n
echo Use 'break <function>' to set breakpoints.\n
echo Use 'step' to step into, 'next' to step over.\n
echo Use 'show_regs' to display registers and code.\n
