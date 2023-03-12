@echo off
rem Compilation...

ET57_build\ET57_build.exe ET-57 > build.S

call d8.bat
call c1.bat 8000000
if not exist %APPNAME%.hex goto err

ET57_build\ET57_build.exe ET-57B > build.S

call d88.bat
call c1.bat 4000000
if not exist %APPNAME%.hex goto err

call d168.bat
call c1.bat 4000000
if not exist %APPNAME%.hex goto err

call d328.bat
call c1.bat 4000000
if not exist %APPNAME%.hex goto err

goto ok

:err
echo.
pause

:ok
