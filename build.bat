@echo off
REM ============================================================================
REM Build script for MDX Player (Windows cross-compile, X68000 native)
REM NO UNDERSCORES - X68000 keyboard compatible
REM ============================================================================

echo Building MDX Player...
echo.

REM ============================================================================
REM For Windows cross-compilation with VASM:
REM ============================================================================

set VASM=C:\dev\vbcc\bin\vasmm68k_mot.exe

if exist "%VASM%" (
    echo Building with VASM...
    "%VASM%" -Fxfile -o outrun.x -nosym outrun.s

    if errorlevel 1 (
        echo ERROR: Assembly failed!
        exit /b 1
    )

    echo Build successful! Output: outrun.x
    echo.
    echo To run in MAME:
    echo   mame.exe x68000 -ramsize 4M -flop1 outrun.x
    echo.
)

REM ============================================================================
REM For X68000 native compilation with CC:
REM ============================================================================

echo.
echo For X68000 CC compiler (cc.x), use these commands:
echo.
echo   1. Simple MDX Player:
echo      as -u mxdrvxc.s
echo      cc -c simplep.c
echo      ln -o simplep.x simplep.o mxdrvxc.o
echo.
echo   2. Probe tool:
echo      as -u mxdrvxc.s
echo      cc -c mxprobe.c
echo      ln -o mxprobe.x mxprobe.o mxdrvxc.o
echo.
echo Files use NO UNDERSCORES for X68000 keyboard compatibility.
echo.

exit /b 0
