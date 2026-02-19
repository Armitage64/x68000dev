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
HELLO_C   = $(BINDIR)/hello_c.x

CFLAGS    = -m68000 -nostdlib -ffreestanding -fno-builtin -fomit-frame-pointer -mpcrel

all: $(PROGRAM) $(HELLO_C)

$(BINDIR) $(OBJDIR):
	mkdir -p $@

# --- Assembly hello world (unchanged) ---
$(PROGRAM): src/hello.s | $(BINDIR)
	$(VASM) -Fxfile -nosym -o $@ $<

# --- C hello world ---
$(OBJDIR)/crt0.o: src/crt0.s | $(OBJDIR)
	$(AS) -m68000 $< -o $@

$(OBJDIR)/hello_c.o: src/hello_c.c | $(OBJDIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BINDIR)/hello_c.elf: $(OBJDIR)/crt0.o $(OBJDIR)/hello_c.o x68k.ld | $(BINDIR)
	$(LD) -T x68k.ld -o $@ $(OBJDIR)/crt0.o $(OBJDIR)/hello_c.o

$(BINDIR)/hello_c.bin: $(BINDIR)/hello_c.elf
	$(OBJCOPY) -O binary $< $@

$(HELLO_C): $(BINDIR)/hello_c.bin tools/make_xfile.py
	python3 tools/make_xfile.py $< $@

# --- Housekeeping ---
install: $(PROGRAM) $(HELLO_C)
	mcopy -i $(BOOT_DISK) -o $(PROGRAM)  ::PROGRAM.X
	mcopy -i $(BOOT_DISK) -o $(HELLO_C)  ::HELLO_C.X

clean:
	rm -rf build

test:
	./tools/test.sh

test-auto:
	./tools/test_gui_automated.sh

.PHONY: all install clean test test-auto
