@echo off
echo Building Hello World...
C:\dev\vbcc\bin\vasmm68k_mot.exe -Fxfile -o hello.x -nosym hello.s
if errorlevel 1 (
    echo ERROR: Assembly failed!
    exit /b 1
)
echo Build successful! Run: hello.x
