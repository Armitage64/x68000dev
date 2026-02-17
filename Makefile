# X68000 Development Environment Makefile

VASM     = ./tools/vasmm68k_mot
BOOT_DISK = MasterDisk_V3.xdf
BINDIR   = build/bin

clean:
	rm -rf build

test:
	./tools/test.sh

.PHONY: clean test
