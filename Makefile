# ============================================================================
# Makefile for Out Run Music Player
# ============================================================================

# Toolchain settings
AS = vasmm68k_mot
ASFLAGS = -Fxfile -nosym

CC = human68k-gcc
OBJCOPY = human68k-objcopy
CFLAGS = -m68000 -O2 -Wall
LDFLAGS = -ldos -liocs

# Targets
ASM_TARGET = outrun.x
C_TARGET = outrunc.x
SIMPLE_TARGET = simple.x
PROBE_TARGET = mxprobe.x

# Default target
all: asm c

# Assembly version
asm: $(ASM_TARGET)

$(ASM_TARGET): outrun.s
	$(AS) $(ASFLAGS) -o $@ $<
	@echo ""
	@echo "Assembly version built: $(ASM_TARGET)"

# C version
c: $(C_TARGET)

$(C_TARGET): outrun.c mxdrv_asm.s
	@echo "Compiling C version..."
	$(CC) $(CFLAGS) -c -o outrun.o outrun.c
	$(CC) -m68000 -c -o mxdrv_asm.o mxdrv_asm.s
	$(CC) -m68000 -o outrunc.elf outrun.o mxdrv_asm.o $(LDFLAGS)
	@echo "Converting to X68000 format..."
	$(OBJCOPY) -O xfile outrunc.elf $@
	@rm -f outrunc.elf outrun.o mxdrv_asm.o
	@echo ""
	@echo "C version built: $(C_TARGET)"

# Simple player (minimal, no work area check)
simple: $(SIMPLE_TARGET)

$(SIMPLE_TARGET): simple_player.c mxdrv_asm.s
	@echo "Compiling simple player..."
	$(CC) $(CFLAGS) -c -o simple_player.o simple_player.c
	$(CC) -m68000 -c -o mxdrv_asm.o mxdrv_asm.s
	$(CC) -m68000 -o simple.elf simple_player.o mxdrv_asm.o $(LDFLAGS)
	@echo "Converting to X68000 format..."
	$(OBJCOPY) -O xfile simple.elf $@
	@rm -f simple.elf simple_player.o mxdrv_asm.o
	@echo ""
	@echo "Simple player built: $(SIMPLE_TARGET)"

# MXDRV probe tool
probe: $(PROBE_TARGET)

$(PROBE_TARGET): mxprobe.c mxdrv_asm.s
	@echo "Compiling MXDRV probe..."
	$(CC) $(CFLAGS) -c -o mxprobe.o mxprobe.c
	$(CC) -m68000 -c -o mxdrv_asm.o mxdrv_asm.s
	$(CC) -m68000 -o mxprobe.elf mxprobe.o mxdrv_asm.o $(LDFLAGS)
	@echo "Converting to X68000 format..."
	$(OBJCOPY) -O xfile mxprobe.elf $@
	@rm -f mxprobe.elf mxprobe.o mxdrv_asm.o
	@echo ""
	@echo "MXDRV probe built: $(PROBE_TARGET)"

# Clean targets
clean:
	rm -f $(ASM_TARGET) $(C_TARGET) $(SIMPLE_TARGET) $(PROBE_TARGET) *.o *.elf *~

# Help
help:
	@echo "Out Run Music Player - Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all    - Build both assembly and C versions"
	@echo "  asm    - Build assembly version (outrun.x)"
	@echo "  c      - Build C version (outrunc.x)"
	@echo "  clean  - Remove built files"
	@echo "  help   - Show this help message"
	@echo ""
	@echo "Requirements:"
	@echo "  Assembly: vasmm68k_mot in PATH"
	@echo "  C:        human68k-gcc in PATH"

.PHONY: all asm c clean help
