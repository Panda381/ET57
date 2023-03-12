@echo off
rem Compilation...
make clean
make all
if not errorlevel 1 goto ok
echo.
pause
:ok
