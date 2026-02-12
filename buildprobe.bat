@echo off
REM ============================================================================
REM Build script for MXDRV Probe Tool (Windows cross-compile)
REM ============================================================================

echo Building MXDRV Probe Tool...

REM Set paths to tools
set GCC=human68k-gcc.exe
set OBJCOPY=human68k-objcopy.exe

REM Check if compiler is available
where %GCC% >nul 2>&1
if errorlevel 1 (
    echo ERROR: %GCC% not found in PATH
    echo.
    echo For cross-compilation, install from:
    echo   https://github.com/Lydux/gcc-4.6.2-human68k
    exit /b 1
)

REM Check if objcopy is available
where %OBJCOPY% >nul 2>&1
if errorlevel 1 (
    echo ERROR: %OBJCOPY% not found in PATH
    exit /b 1
)

REM Compile and link
echo Compiling mxprobe.c...
%GCC% -m68000 -O2 -Wall -c -o mxprobe.o mxprobe.c

if errorlevel 1 (
    echo ERROR: C compilation failed!
    exit /b 1
)

echo Assembling MXDRV wrapper (mxdrvasm.s)...
%GCC% -m68000 -c -o mxdrvasm.o mxdrvasm.s

if errorlevel 1 (
    echo ERROR: Assembly failed!
    exit /b 1
)

echo Linking...
%GCC% -m68000 -o mxprobe.elf mxprobe.o mxdrvasm.o -ldos -liocs

if errorlevel 1 (
    echo ERROR: Linking failed!
    exit /b 1
)

echo Converting to X68000 format...
%OBJCOPY% -O xfile mxprobe.elf mxprobe.x

if errorlevel 1 (
    echo ERROR: Conversion failed!
    exit /b 1
)

REM Clean up
if exist mxprobe.elf del mxprobe.elf
if exist mxprobe.o del mxprobe.o
if exist mxdrvasm.o del mxdrvasm.o

echo.
echo ============================================================================
echo Build successful! Output: mxprobe.x
echo ============================================================================
echo.
echo This will test all MXDRV functions 0-10 and show what they return.
echo.
echo To run:
echo   1. Load mxdrv.x
echo   2. Run mxprobe.x
echo.

exit /b 0
