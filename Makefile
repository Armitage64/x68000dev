# ============================================================================
# Makefile for Out Run Music Player
# ============================================================================

# Toolchain settings
AS = vasmm68k_mot
ASFLAGS = -Fhunk -nosym

CC = m68k-human68k-gcc
OBJCOPY = m68k-human68k-objcopy
CFLAGS = -m68000 -O2 -Wall
LDFLAGS = -ldos -liocs

# Targets
ASM_TARGET = outrun.x
C_TARGET = outrunc.x

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

$(C_TARGET): outrun.c
	@echo "Compiling C version..."
	$(CC) $(CFLAGS) -o outrunc.elf $< $(LDFLAGS)
	@echo "Converting to X68000 format..."
	$(OBJCOPY) -O xfile outrunc.elf $@
	@rm -f outrunc.elf
	@echo ""
	@echo "C version built: $(C_TARGET)"

# Clean targets
clean:
	rm -f $(ASM_TARGET) $(C_TARGET) *.o *.elf *~

# Help
help:
	@echo "Out Run Music Player - Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all    - Build both assembly and C versions"
	@echo "  asm    - Build assembly version (outrun.x)"
	@echo "  c      - Build C version (outrun_c.x)"
	@echo "  clean  - Remove built files"
	@echo "  help   - Show this help message"
	@echo ""
	@echo "Requirements:"
	@echo "  Assembly: vasmm68k_mot in PATH"
	@echo "  C:        human68k-gcc in PATH"

.PHONY: all asm c clean help
