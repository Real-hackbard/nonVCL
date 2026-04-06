@echo off
call resbuild.bat
echo {$DEFINE STATIC} > Type.inc
dcc32 Sample.dpr
del SampleSTATIC.exe
ren Sample.exe SampleSTATIC.exe
echo {DEFINE STATIC} > Type.inc
dcc32 Sample.dpr
del SampleDYNAMIC.exe
ren Sample.exe SampleDYNAMIC.exe
dcc32 SampleDLL.dpr
rem Pack and set checksum
rem upx -9 SampleSTATIC.exe
rem upx -9 SampleDYNAMIC.exe
rem upx -9 SampleDLL.dll
setcsum SampleSTATIC.exe /a
setcsum SampleDYNAMIC.exe /a
setcsum SampleDLL.dll /a
rem remove trash files.
del *.dsm >NUL
del *.~* >NUL
del *.cfg >NUL
del *.dsk >NUL
del *.dof >NUL
pause
