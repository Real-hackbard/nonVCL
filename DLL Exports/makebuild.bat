@echo off

:: -- Hilfe aufrufen, wenn erforderlich
if "%1"=="" goto Syntax

:Work
call cleanup.bat
brcc32 skript1.rc -foresource.res
dcc32 %1.dpr
move %1.exe ..
call cleanup.bat

:Compress
cd ..
cd ..
del %1.zip
del %1sfx.exe
PACOMP -a -r -p %1.zip %1\*.*
ren %1.zip %1sfx.zip
POWERARC -tosfx %1sfx.zip
goto TheEnd

:: -- Hilfe anzeigen
:Syntax
echo make.bat v4
echo.
echo   make RC-Datei DPR-Datei Move-Filter ZIP-Name
echo.
echo Beispiel:
echo.
echo   make script1 Project1 *.exe SfxTest
echo.
echo - erzeugt aus Script1.rc -> Script1.res
echo - kompiliert Project1.dpr
echo - kopiert *.exe in das übergeordnete Verzeichnis
echo - benutzt WinRAR zum Erzeugen des Exe-Archivs "SfxTest.exe"
echo.

:TheEnd