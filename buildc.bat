@echo off
REM ============================================================================
REM Build script for MDX Player - C Version (Windows cross-compile)
REM NO UNDERSCORES - X68000 keyboard compatible
REM ============================================================================

echo Building MDX Player (C version)...

REM Set paths to tools
set GCC=human68k-gcc.exe
set OBJCOPY=human68k-objcopy.exe

REM Check if compiler is available
where %GCC% >nul 2>&1
if errorlevel 1 (
    echo ERROR: %GCC% not found in PATH
    echo.
    echo This script is for Windows cross-compilation with human68k-gcc.
    echo.
    echo If you are on the X68000, use these commands instead:
    echo   as -u mxdrvxc.s
    echo   xc -c simplep.c
    echo   ln -o simplep.x simplep.o mxdrvxc.o
    echo.
    echo For cross-compilation, install from:
    echo   https://github.com/Lydux/gcc-4.6.2-human68k
    exit /b 1
)

REM Check if objcopy is available
where %OBJCOPY% >nul 2>&1
if errorlevel 1 (
    echo ERROR: %OBJCOPY% not found in PATH
    echo Please install binutils-2.22-human68k
    exit /b 1
)

REM Compile and link the C source and assembly wrapper
echo Compiling C source (simplep.c)...
%GCC% -m68000 -O2 -Wall -c -o simplep.o simplep.c

if errorlevel 1 (
    echo ERROR: C compilation failed!
    exit /b 1
)

echo Assembling MXDRV wrapper (mxdrvasm.s - GCC syntax)...
%GCC% -m68000 -c -o mxdrvasm.o mxdrvasm.s

if errorlevel 1 (
    echo ERROR: Assembly failed!
    exit /b 1
)

echo Linking...
%GCC% -m68000 -o simplep.elf simplep.o mxdrvasm.o -ldos -liocs

if errorlevel 1 (
    echo ERROR: Linking failed!
    exit /b 1
)

REM Convert to X68000 .X format
echo Converting to X68000 format...
%OBJCOPY% -O xfile simplep.elf simplep.x

if errorlevel 1 (
    echo ERROR: Conversion to X68000 format failed!
    exit /b 1
)

REM Clean up intermediate files
if exist simplep.elf del simplep.elf
if exist simplep.o del simplep.o
if exist mxdrvasm.o del mxdrvasm.o

echo.
echo ============================================================================
echo Build successful! Output: simplep.x
echo ============================================================================
echo.
echo To run in MAME:
echo   mame.exe x68000 -ramsize 4M -flop1 simplep.x
echo.
echo Make sure MXDRV30.X and LAST.MDX are in the same directory!
echo.
echo Files use NO UNDERSCORES for X68000 keyboard compatibility.
echo ============================================================================

exit /b 0
