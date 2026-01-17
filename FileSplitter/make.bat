@echo off
echo Kompilieren der Ressourcen...
echo =============================
rcstamp res\resource.rc *.*.*.+
brcc32 res\resource.rc resources\-foresource.res
echo.
echo Loeschen alter kompilierte Units...
echo ===================================
del /s *.dcu
echo.
echo Kompilieren der Anwendung...
echo.
C:\Programme\Borland\BDS\4.0\Bin\dcc32 FileSplitter.dpr
echo.
echo Loeschen der temporaeren Dateien und der kompilierten Units...
echo ==============================================================
del /s *.~*
del /s *.dcu
echo.
echo Packen mit UPX...
echo =================
upx -9 ..\FileSplitter.exe
echo.
set /P CHS=Programm starten mit [Return]. Beenden mit "E":
if /I "%CHS%"=="E" goto :ENDE

start ..\FileSplitter.exe

:ENDE