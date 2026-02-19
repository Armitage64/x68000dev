# X68000 Development Environment Makefile

CC        = m68k-linux-gnu-gcc
AS        = m68k-linux-gnu-as
LD        = m68k-linux-gnu-ld
OBJCOPY   = m68k-linux-gnu-objcopy
VASM      = ./tools/vasmm68k_mot
BOOT_DISK = MasterDisk_V3.xdf
BINDIR    = build/bin
OBJDIR    = build/obj
PROGRAM   = $(BINDIR)/program.x
HELLOC    = $(BINDIR)/helloc.x

CFLAGS    = -m68000 -nostdlib -ffreestanding -fno-builtin -fomit-frame-pointer -mpcrel

all: $(PROGRAM) $(HELLOC)

$(BINDIR) $(OBJDIR):
	mkdir -p $@

# --- Assembly hello world (unchanged) ---
$(PROGRAM): src/hello.s | $(BINDIR)
	$(VASM) -Fxfile -nosym -o $@ $<

# --- C hello world ---
$(OBJDIR)/crt0.o: src/crt0.s | $(OBJDIR)
	$(AS) -m68000 $< -o $@

$(OBJDIR)/helloc.o: src/helloc.c | $(OBJDIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BINDIR)/helloc.elf: $(OBJDIR)/crt0.o $(OBJDIR)/helloc.o x68k.ld | $(BINDIR)
	$(LD) -T x68k.ld -o $@ $(OBJDIR)/crt0.o $(OBJDIR)/helloc.o

$(BINDIR)/helloc.bin: $(BINDIR)/helloc.elf
	$(OBJCOPY) -O binary $< $@

$(HELLOC): $(BINDIR)/helloc.bin tools/make_xfile.py
	python3 tools/make_xfile.py $< $@

# --- Housekeeping ---
install: $(PROGRAM) $(HELLOC)
	mcopy -i $(BOOT_DISK) -o $(PROGRAM)  ::PROGRAM.X
	mcopy -i $(BOOT_DISK) -o $(HELLOC)   ::HELLOC.X

clean:
	rm -rf build

test:
	./tools/test.sh

test-auto:
	./tools/test_gui_automated.sh

.PHONY: all install clean test test-auto
