@echo off
echo Building MXDRV test...
human68k-gcc.exe -m68000 -O2 -Wall -c -o mxtest.o mxtest.c
human68k-gcc.exe -m68000 -c -o mxdrv_asm.o mxdrv_asm.s
human68k-gcc.exe -m68000 -o mxtest.elf mxtest.o mxdrv_asm.o -ldos -liocs
human68k-objcopy.exe -O xfile mxtest.elf mxtest.x
del mxtest.elf mxtest.o mxdrv_asm.o
echo Build successful! Run: mxtest.x
