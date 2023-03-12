@echo off
rem Compilation...

if exist %APPNAME%.hex del %APPNAME%.hex

echo Compile %APPNAME%...
make all -s PROJECT=%APPNAME% MCU=%CPUNAME% F_CPU=%1
rem 2> a
if errorlevel 1 goto err
avr-nm -n %APPNAME%.elf > %APPNAME%.sym
avr-size -C --mcu=%CPUNAME% %APPNAME%.elf
avr-objdump -d -S -m avr %APPNAME%.elf > %APPNAME%.lst
goto ok

:err
if exist %APPNAME%.elf avr-size -C --mcu=%CPUNAME% %APPNAME%.elf
rem echo.
rem pause

:ok
if exist *.o del *.o
