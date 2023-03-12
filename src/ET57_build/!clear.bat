@echo off

call !clear1.bat Debug
call !clear1.bat Release

if exist *.pdb del *.pdb
if exist *.user del *.user

if exist *.ncb del *.ncb
attrib -H ET57_build.suo > nul
if exist ET57_build.suo del ET57_build.suo
