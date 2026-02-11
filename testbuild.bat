@echo off
echo Building test program...

.\has.x -e -u -w0 test.s -o test.x
if errorlevel 1 (
    echo ERROR: Assembly failed!
    exit /b 1
)

echo.
echo Build successful! test.x created.
echo.
echo Running test...
echo.
test.x
