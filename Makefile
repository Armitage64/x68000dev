# X68000 Development Environment Makefile

VASM      = ./tools/vasmm68k_mot
BOOT_DISK = MasterDisk_V3.xdf
BINDIR    = build/bin
PROGRAM   = $(BINDIR)/program.x

all: $(PROGRAM)

$(BINDIR):
	mkdir -p $(BINDIR)

$(PROGRAM): src/hello.s | $(BINDIR)
	$(VASM) -Fxfile -nosym -o $@ $<

install: $(PROGRAM)
	mcopy -i $(BOOT_DISK) -o $(PROGRAM) ::PROGRAM.X

clean:
	rm -rf build

test:
	./tools/test.sh

test-auto:
	./tools/test_gui_automated.sh

.PHONY: all install clean test test-auto
