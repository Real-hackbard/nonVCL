unit CommDlg_Fragment;

interface

uses
  Windows;

type
  POpenFilenameA = ^TOpenFilenameA;
  POpenFilenameW = ^TOpenFilenameW;
  POpenFilename = POpenFilenameA;

  {$EXTERNALSYM tagOFNA}
  tagOFNA = packed record
    lStructSize: DWORD;
    hWndOwner: HWND;
    hInstance: HINST;
    lpstrFilter: PAnsiChar;
    lpstrCustomFilter: PAnsiChar;
    nMaxCustFilter: DWORD;
    nFilterIndex: DWORD;
    lpstrFile: PAnsiChar;
    nMaxFile: DWORD;
    lpstrFileTitle: PAnsiChar;
    nMaxFileTitle: DWORD;
    lpstrInitialDir: PAnsiChar;
    lpstrTitle: PAnsiChar;
    Flags: DWORD;
    nFileOffset: Word;
    nFileExtension: Word;
    lpstrDefExt: PAnsiChar;
    lCustData: LPARAM;
    lpfnHook: function(Wnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): UINT stdcall;
    lpTemplateName: PAnsiChar;
    pvReserved: pointer;
    dwReserved: dword;
    FlagsEx: dword;
  end;

  {$EXTERNALSYM tagOFNW}
  tagOFNW = packed record
    lStructSize: DWORD;
    hWndOwner: HWND;
    hInstance: HINST;
    lpstrFilter: PWideChar;
    lpstrCustomFilter: PWideChar;
    nMaxCustFilter: DWORD;
    nFilterIndex: DWORD;
    lpstrFile: PWideChar;
    nMaxFile: DWORD;
    lpstrFileTitle: PWideChar;
    nMaxFileTitle: DWORD;
    lpstrInitialDir: PWideChar;
    lpstrTitle: PWideChar;
    Flags: DWORD;
    nFileOffset: Word;
    nFileExtension: Word;
    lpstrDefExt: PWideChar;
    lCustData: LPARAM;
    lpfnHook: function(Wnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): UINT stdcall;
    lpTemplateName: PWideChar;
    pvReserved: pointer;
    dwReserved: dword;
    FlagsEx: dword;
  end;

  {$EXTERNALSYM tagOFN}
  tagOFN = tagOFNA;
  TOpenFilenameA = tagOFNA;
  TOpenFilenameW = tagOFNW;
  TOpenFilename = TOpenFilenameA;

  {$EXTERNALSYM OPENFILENAMEA}
  OPENFILENAMEA = tagOFNA;
  {$EXTERNALSYM OPENFILENAMEW}
  OPENFILENAMEW = tagOFNW;
  {$EXTERNALSYM OPENFILENAME}
  OPENFILENAME = OPENFILENAMEA;

const
  {$EXTERNALSYM OPENFILENAME_SIZE_VERSION_400A}
  OPENFILENAME_SIZE_VERSION_400A = sizeof(TOpenFileNameA) -
    sizeof(pointer) - (2 * sizeof(dword));
  {$EXTERNALSYM OPENFILENAME_SIZE_VERSION_400W}
  OPENFILENAME_SIZE_VERSION_400W = sizeof(TOpenFileNameW) -
    sizeof(pointer) - (2 * sizeof(dword));
  {$EXTERNALSYM OPENFILENAME_SIZE_VERSION_400}
  OPENFILENAME_SIZE_VERSION_400  = OPENFILENAME_SIZE_VERSION_400A;

const
  {$EXTERNALSYM OFN_DONTADDTORECENT}
  OFN_DONTADDTORECENT = $02000000;
  {$EXTERNALSYM OFN_FORCESHOWHIDDEN}
  OFN_FORCESHOWHIDDEN = $10000000;    // Show All files including System and hidden files
  {$EXTERNALSYM OFN_EX_NOPLACESBAR}
  OFN_EX_NOPLACESBAR  = $00000001;


{$EXTERNALSYM GetOpenFileNameA}
function GetOpenFileNameA(var OpenFile: TOpenFilenameA): Bool; stdcall;
{$EXTERNALSYM GetOpenFileNameW}
function GetOpenFileNameW(var OpenFile: TOpenFilenameW): Bool; stdcall;
{$EXTERNALSYM GetOpenFileName}
function GetOpenFileName(var OpenFile: TOpenFilename): Bool; stdcall;
{$EXTERNALSYM GetSaveFileNameA}
function GetSaveFileNameA(var OpenFile: TOpenFilenameA): Bool; stdcall;
{$EXTERNALSYM GetSaveFileNameW}
function GetSaveFileNameW(var OpenFile: TOpenFilenameW): Bool; stdcall;
{$EXTERNALSYM GetSaveFileName}
function GetSaveFileName(var OpenFile: TOpenFilename): Bool; stdcall;


{$EXTERNALSYM GetOpenFileNamePreviewA}
function GetOpenFileNamePreviewA(var OpenFile: TOpenFileNameA): Bool; stdcall;
{$EXTERNALSYM GetOpenFileNamePreviewW}
function GetOpenFileNamePreviewW(var OpenFile: TOpenFileNameW): Bool; stdcall;
{$EXTERNALSYM GetOpenFileNamePreview}
function GetOpenFileNamePreview(var OpenFile: TOpenFileNameA): Bool; stdcall;

{$EXTERNALSYM GetSaveFileNamePreviewA}
function GetSaveFileNamePreviewA(var OpenFile: TOpenFileNameA): Bool; stdcall;
{$EXTERNALSYM GetSaveFileNamePreviewW}
function GetSaveFileNamePreviewW(var OpenFile: TOpenFileNameW): Bool; stdcall;
{$EXTERNALSYM GetSaveFileNamePreview}
function GetSaveFileNamePreview(var OpenFile: TOpenFileNameA): Bool; stdcall;



implementation

function GetOpenFileNameA; external 'comdlg32.dll'  name 'GetOpenFileNameA';
function GetOpenFileNameW; external 'comdlg32.dll'  name 'GetOpenFileNameW';
function GetOpenFileName;  external 'comdlg32.dll'  name 'GetOpenFileNameA';
function GetSaveFileNameA; external 'comdlg32.dll'  name 'GetSaveFileNameA';
function GetSaveFileNameW; external 'comdlg32.dll'  name 'GetSaveFileNameW';
function GetSaveFileName;  external 'comdlg32.dll'  name 'GetSaveFileNameA';

function GetOpenFileNamePreviewA; external 'msvfw32.dll' name 'GetOpenFileNamePreviewA';
function GetOpenFileNamePreviewW; external 'msvfw32.dll' name 'GetOpenFileNamePreviewW';
function GetOpenFileNamePreview;  external 'msvfw32.dll' name 'GetOpenFileNamePreviewA';
function GetSaveFileNamePreviewA; external 'msvfw32.dll' name 'GetSaveFileNamePreviewA';
function GetSaveFileNamePreviewW; external 'msvfw32.dll' name 'GetSaveFileNamePreviewW';
function GetSaveFileNamePreview;  external 'msvfw32.dll' name 'GetSaveFileNamePreviewA';

end.
