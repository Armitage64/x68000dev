@echo off
REM ============================================================================
REM Build script for Out Run Music Player - C Version (Windows)
REM ============================================================================

echo Building Out Run Music Player (C version)...

REM Set paths to tools
set GCC=human68k-gcc.exe
set VASM=C:\dev\vbcc\bin\vasmm68k_mot.exe

REM Check if compiler is available
where %GCC% >nul 2>&1
if errorlevel 1 (
    echo ERROR: %GCC% not found in PATH
    echo Please install the Human68k cross-compiler toolchain
    echo.
    echo Toolchain can be built from: https://github.com/Lydux/gcc-4.6.2-human68k
    exit /b 1
)

REM Compile C source to assembly
echo Compiling C source to assembly...
%GCC% -m68000 -O2 -Wall -S -o outrun.s outrun.c

if errorlevel 1 (
    echo ERROR: C compilation failed!
    exit /b 1
)

REM Assemble to X68000 format using vasm (known to work)
echo Assembling to X68000 format...
%VASM% -Fxfile -o outrunc.x -nosym outrun.s

if errorlevel 1 (
    echo ERROR: Assembly failed!
    exit /b 1
)

REM Clean up intermediate files
if exist outrun.s del outrun.s

echo Build successful! Output: outrunc.x
echo.
echo To run in MAME:
echo   C:\dev\mame\mame.exe x68000 -ramsize 4M -flop1 outrunc.x
echo.
echo Make sure MXDRV.X and the .MDX files are in the same directory!

exit /b 0
