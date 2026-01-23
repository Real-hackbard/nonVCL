unit DllVersion;

interface

uses
  Windows;

type
  {$EXTERNALSYM _DLLVERSIONINFO}
  _DLLVERSIONINFO =
    packed record
      cbSize,
      dwMajorVersion,
      dwMinorVersion,
      dwBuildNumber,
      dwPlatformID : dword;
    end;
  TDllVersionInfo = _DLLVERSIONINFO;

  {$EXTERNALSYM _DLLVERSIONINFO2}
  _DLLVERSIONINFO2 =
    packed record
      info1 : _DLLVERSIONINFO;
      dwFlags : dword;
      ul1Version : ULONG;
    end;
  TDllVersionInfo2 = _DLLVERSIONINFO2;

type
  TDllGetVersion  = function(pdvi: POINTER): HRESULT; stdcall;
var
  DllGetVersion   : TDllGetVersion;

implementation
end.