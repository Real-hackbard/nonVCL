' Toolbar Sample
' Win32-API-Tutorials für Delphi

Dim Sh, regKey
Set Sh = CreateObject("WScript.Shell")

Sh.RegDelete "HKCU\Software\Win32-API-Tutorials\Toolbar-Demo\"
Sh.RegDelete "HKCU\Software\Win32-API-Tutorials\"