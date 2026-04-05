unit ShlObj_Fragment;

interface

uses
  Windows,
  Messages,
  ShlObj;

//-------------------------------------------------------------------------
//
// SHBrowseForFolder API
//
//-------------------------------------------------------------------------

const
  {$EXTERNALSYM BIF_NEWDIALOGSTYLE}
  BIF_NEWDIALOGSTYLE     = $0040;       // Use the new dialog layout with the ability to resize
                                        // Caller needs to call OleInitialize() before using this API

  {$EXTERNALSYM BIF_USENEWUI}
  BIF_USENEWUI           = BIF_NEWDIALOGSTYLE or BIF_EDITBOX;

  {$EXTERNALSYM BIF_BROWSEINCLUDEURLS}
  BIF_BROWSEINCLUDEURLS  = $0080;   // Allow URLs to be displayed or entered. (Requires BIF_USENEWUI)
  {$EXTERNALSYM BIF_UAHINT}
  BIF_UAHINT             = $0100;   // Add a UA hint to the dialog, in place of the edit box. May not be combined with BIF_EDITBOX
  {$EXTERNALSYM BIF_NONEWFOLDERBUTTON}
  BIF_NONEWFOLDERBUTTON  = $0200;   // Do not add the "New Folder" button to the dialog.  Only applicable with BIF_NEWDIALOGSTYLE.
  {$EXTERNALSYM BIF_NOTRANSLATETARGETS}
  BIF_NOTRANSLATETARGETS = $0400;   // don't traverse target as shortcut

  {$EXTERNALSYM BIF_SHAREABLE}
  BIF_SHAREABLE          = $8000;  // sharable resources displayed (remote shares, requires BIF_USENEWUI)

  {$EXTERNALSYM BFFM_IUNKNOWN}
  BFFM_IUNKNOWN           = 5;  // provides IUnknown to client. lParam: IUnknown*

  {$EXTERNALSYM BFFM_SETOKTEXT}
  BFFM_SETOKTEXT          = WM_USER + 105; // Unicode only
  {$EXTERNALSYM BFFM_SETEXPANDED}
  BFFM_SETEXPANDED        = WM_USER + 106; // Unicode only



//-------------------------------------------------------------------------
//
// SHAutoComplete
//
//-------------------------------------------------------------------------


// SHAutoComplete
//      hwndEdit - HWND of editbox, ComboBox or ComboBoxEx.
//      dwFlags - Flags to indicate what to AutoAppend or AutoSuggest for the editbox.
//
// WARNING:
//    Caller needs to have called CoInitialize() or OleInitialize()
//    and cannot call CoUninit/OleUninit until after
//    WM_DESTROY on hwndEdit.
//
//  dwFlags values:

const
  {$EXTERNALSYM SHACF_DEFAULT}
  SHACF_DEFAULT                   = $00000000;  // Currently (SHACF_FILESYSTEM | SHACF_URLALL)
  {$EXTERNALSYM SHACF_FILESYSTEM}
  SHACF_FILESYSTEM                = $00000001;  // This includes the File System as well as the rest of the shell (Desktop\My Computer\Control Panel\)
  {$EXTERNALSYM SHACF_URLHISTORY}
  SHACF_URLHISTORY                = $00000002;  // URLs in the User's History
  {$EXTERNALSYM SHACF_URLMRU}
  SHACF_URLMRU                    = $00000004;  // URLs in the User's Recently Used list.
  {$EXTERNALSYM SHACF_USETAB}
  SHACF_USETAB                    = $00000008;  // Use the tab to move thru the autocomplete possibilities instead of to the next dialog/window control.
  {$EXTERNALSYM SHACF_FILESYS_ONLY}
  SHACF_FILESYS_ONLY              = $00000010;  // This includes the File System
  {$EXTERNALSYM SHACF_URLALL}
  SHACF_URLALL                    = SHACF_URLHISTORY or SHACF_URLMRU;

  {$EXTERNALSYM SHACF_FILESYS_DIRS}
  SHACF_FILESYS_DIRS              = $00000020;  // Same as SHACF_FILESYS_ONLY except it only includes directories, UNC servers, and UNC server shares.

  {$EXTERNALSYM SHACF_AUTOSUGGEST_FORCE_ON}
  SHACF_AUTOSUGGEST_FORCE_ON      = $10000000;  // Ignore the registry default and force the feature on.
  {$EXTERNALSYM SHACF_AUTOSUGGEST_FORCE_OFF}
  SHACF_AUTOSUGGEST_FORCE_OFF     = $20000000;  // Ignore the registry default and force the feature off.
  {$EXTERNALSYM SHACF_AUTOAPPEND_FORCE_ON}
  SHACF_AUTOAPPEND_FORCE_ON       = $40000000;  // Ignore the registry default and force the feature on. (Also know as AutoComplete)
  {$EXTERNALSYM SHACF_AUTOAPPEND_FORCE_OFF}
  SHACF_AUTOAPPEND_FORCE_OFF      = $80000000;  // Ignore the registry default and force the feature off. (Also know as AutoComplete)


type
  TSHAutoComplete = function(hwndEdit: HWND; dwFlags: DWORD):
    HRESULT; stdcall;
var
  SHAutoComplete  : TSHAutoComplete = nil;


implementation

uses
  DllVersion;

function SHAutoCompleteError(hwndEdit: HWND; dwFlags: dword): HRESULT; stdcall;
begin
  Result := 0;
  MessageBox(hwndEdit,'Die Funktion "SHAutoComplete" konnte nicht geladen werden.',
    nil,MB_OK or MB_ICONEXCLAMATION);
end;


const
  shlwapi = 'shlwapi.dll';
var
  dll     : dword = 0;
  dllver  : TDllVersionInfo;

initialization
  dll := LoadLibrary(shlwapi);
  if(dll <> 0) then begin
    DllGetVersion := GetProcAddress(dll,'DllGetVersion');
    if(@DllGetVersion <> nil) then begin
      ZeroMemory(@dllver,sizeof(dllver));
      dllver.cbSize := sizeof(dllver);

      if(DllGetVersion(@dllver) = NOERROR) and
        (dllver.dwMajorVersion * 100 + dllver.dwMinorVersion >= 500) then
      begin
        SHAutoComplete := GetProcAddress(dll,'SHAutoComplete');
      end;
    end;

    if(@SHAutoComplete = nil) then begin
      FreeLibrary(dll);
      dll := 0;
      SHAutoComplete := @SHAutoCompleteError;
    end;
  end;
finalization
  if(dll <> 0) then
    FreeLibrary(dll);
end.