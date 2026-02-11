@echo off
REM ============================================================================
REM Build script for Out Run Music Player - C Version (Windows)
REM ============================================================================

echo Building Out Run Music Player (C version)...

REM Set paths to tools
set GCC=human68k-gcc.exe
set OBJCOPY=human68k-objcopy.exe

REM Check if compiler is available
where %GCC% >nul 2>&1
if errorlevel 1 (
    echo ERROR: %GCC% not found in PATH
    echo Please install the Human68k cross-compiler toolchain
    echo.
    echo Toolchain can be built from: https://github.com/Lydux/gcc-4.6.2-human68k
    exit /b 1
)

REM Check if objcopy is available
where %OBJCOPY% >nul 2>&1
if errorlevel 1 (
    echo ERROR: %OBJCOPY% not found in PATH
    echo Please install binutils-2.22-human68k
    exit /b 1
)

REM Compile and link the C source (with inline assembly)
echo Compiling C source...
%GCC% -m68000 -O2 -Wall -c -o outrun.o outrun.c

if errorlevel 1 (
    echo ERROR: C compilation failed!
    exit /b 1
)

echo Linking...
%GCC% -m68000 -o outrunc.x outrun.o -ldos -liocs

if errorlevel 1 (
    echo ERROR: Linking failed!
    exit /b 1
)

REM Clean up intermediate files
if exist outrun.o del outrun.o

echo Build successful! Output: outrunc.x
echo.
echo To run in MAME:
echo   C:\dev\mame\mame.exe x68000 -ramsize 4M -flop1 outrunc.x
echo.
echo Make sure MXDRV.X and the .MDX files are in the same directory!

exit /b 0
