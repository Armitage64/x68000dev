@echo off
REM ============================================================================
REM Build script for OUT RUN Player - C Version (Windows cross-compile)
REM NO UNDERSCORES - X68000 keyboard compatible
REM ============================================================================

echo Building OUT RUN Music Player (C version)...

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
    echo   cc -c outrun.c
    echo   ln -o outrun.x outrun.o mxdrvxc.o
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
echo Compiling C source (outrun.c)...
%GCC% -m68000 -O2 -Wall -c -o outrun.o outrun.c

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
%GCC% -m68000 -o outrunc.elf outrun.o mxdrvasm.o -ldos -liocs

if errorlevel 1 (
    echo ERROR: Linking failed!
    exit /b 1
)

REM Convert to X68000 .X format
echo Converting to X68000 format...
%OBJCOPY% -O xfile outrunc.elf outrunc.x

if errorlevel 1 (
    echo ERROR: Conversion to X68000 format failed!
    exit /b 1
)

REM Clean up intermediate files
if exist outrunc.elf del outrunc.elf
if exist outrun.o del outrun.o
if exist mxdrvasm.o del mxdrvasm.o

echo.
echo ============================================================================
echo Build successful! Output: outrunc.x
echo ============================================================================
echo.
echo To run on X68000:
echo   1. Load MXDRV30.X first
echo   2. Run outrunc.x
echo.
echo Make sure these MDX files are present:
echo   - MAGICAL.MDX (Magical Sound Shower)
echo   - PASSING.MDX (Passing Breeze)
echo   - SPLASH.MDX  (Splash Wave)
echo   - LAST.MDX    (Last Wave)
echo.
echo ============================================================================

exit /b 0
