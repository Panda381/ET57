@echo off
rem Delete...
set APPNAME=ET57_168
set CPUNAME=atmega168

if exist *.o del *.o
if exist %APPNAME%.lst del %APPNAME%.lst
if exist %APPNAME%.sym del %APPNAME%.sym
if exist %APPNAME%.bin del %APPNAME%.bin
if exist %APPNAME%.elf del %APPNAME%.elf
