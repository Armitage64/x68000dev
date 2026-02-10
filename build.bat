@echo off
REM ============================================================================
REM Build script for Out Run Music Player (Windows)
REM ============================================================================

echo Building Out Run Music Player...

REM Set paths to tools
set VASM=C:\dev\vbcc\bin\vasmm68k_mot.exe
set VLINK=C:\dev\vbcc\bin\vlink.exe

REM Check if VASM exists
if not exist "%VASM%" (
    echo ERROR: VASM not found at %VASM%
    echo Please update the VASM path in this script
    exit /b 1
)

REM Assemble the source
"%VASM%" -Fhunk -o outrun.x -nosym outrun.s

if errorlevel 1 (
    echo ERROR: Assembly failed!
    exit /b 1
)

echo Build successful! Output: outrun.x
echo.
echo To run in MAME:
echo   C:\dev\mame\mame.exe x68000 -ramsize 4M -flop1 outrun.x
echo.
echo Make sure MXDRV.X and the .MDX files are in the same directory!

exit /b 0
