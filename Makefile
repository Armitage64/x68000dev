# ============================================================================
# Makefile for Out Run Music Player
# ============================================================================

# Toolchain settings
AS = vasmm68k_mot
ASFLAGS = -Fhunk -nosym

CC = human68k-gcc
CFLAGS = -O2 -Wall
LDFLAGS =

# Targets
ASM_TARGET = outrun.x
C_TARGET = outrun_c.x

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
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)
	@echo ""
	@echo "C version built: $(C_TARGET)"

# Clean targets
clean:
	rm -f $(ASM_TARGET) $(C_TARGET) *.o *~

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
