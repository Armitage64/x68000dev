# X68000 Development Environment Makefile
# Targets the Sharp X68000 using m68k cross-compiler

# Toolchain
VASM = ./tools/vasmm68k_mot
CC = m68k-linux-gnu-gcc
AS = m68k-linux-gnu-as
LD = m68k-linux-gnu-ld
OBJCOPY = m68k-linux-gnu-objcopy

# Compiler flags
CFLAGS = -m68000 -O2 -Wall -Wextra -Iinclude -fomit-frame-pointer -nostdlib -ffreestanding
LDFLAGS = -T x68k.ld -nostdlib
ASFLAGS = -m68000

# Directories
SRCDIR = src
OBJDIR = build/obj
BINDIR = build/bin
FLOPPYDIR = build/floppy
TESTDIR = tests

# Target
TARGET = $(BINDIR)/program.x
BOOT_DISK = MasterDisk_V3.xdf

# Sources
C_SRCS = $(wildcard $(SRCDIR)/*.c $(SRCDIR)/*/*.c)
ASM_SRCS = $(wildcard $(SRCDIR)/*.s $(SRCDIR)/*/*.s)
C_OBJS = $(C_SRCS:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
ASM_OBJS = $(ASM_SRCS:$(SRCDIR)/%.s=$(OBJDIR)/%.o)
OBJS = $(ASM_OBJS) $(C_OBJS)

# Build rules
all: $(TARGET) install

# Use VASM to build X68000 executable with proper .X format
$(TARGET): $(SRCDIR)/test_vasm.s
	@mkdir -p $(BINDIR)
	$(VASM) -Fxfile -o $@ -nosym $<
	@echo "Build successful: $(TARGET)"
	@ls -lh $@

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%.o: $(SRCDIR)/%.s
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) -o $@ $<

install: $(TARGET)
	@echo "Installing program to boot disk..."
	mcopy -i $(BOOT_DISK) -o $(TARGET) ::PROGRAM.X
	@echo "Program installed to $(BOOT_DISK)"

clean:
	rm -rf $(OBJDIR) $(BINDIR)

test: install
	./tools/test.sh

test-auto: install
	./tools/test_automated.sh

test-headless: install
	./tools/test_headless.sh

verify:
	./tools/verify.sh

.PHONY: all clean test test-auto test-headless verify install
