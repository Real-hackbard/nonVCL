program peoptim;

{$R peoptim.res}

uses
  Windows, Messages, PE_Files;


const       { Dialog's controls ID }
  MAIN_DIALOG                    =    101;
  ABOUT_DIALOG                   =    102;
  MAIN_ICON                      =    201;
  LOGO                           =    301;
  FILE_EDIT                      =    401;
  INFO_EDIT                      =    402;
  FILE_BUTTON                    =    501;
  PROCESS_BUTTON                 =    502;
  ABOUT_BUTTON                   =    503;
  CLOSE_BUTTON                   =    504;
  ABOUT_CLOSE_BUTTON             =    505;
  BACKUP_BOX                     =    601;
  RELOC_BOX                      =    602;
  RELOCDLL_BOX                   =    603;
  WIPE_BOX                       =    604;
  OVERLAY_BOX                    =    605;
  SAVE_BOX                       =    606;

type
  TOpenFileName = packed record
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
    lpfnHook: function(Wnd: HWND; Msg: UINT; wParam: WPARAM;
      lParam: LPARAM): UINT stdcall;
    lpTemplateName: PAnsiChar;
  end;

const
  OFN_LONGNAMES     = $00200000;
  OFN_EXPLORER      = $00080000;
  OFN_FILEMUSTEXIST = $00001000;
  OFN_PATHMUSTEXIST = $00000800;
  OFN_HIDEREADONLY  = $00000004;

function GetOpenFileNameA(var OpenFile: TOpenFileName): Bool; stdcall;
external 'comdlg32.dll' name 'GetOpenFileNameA';


var
  Inst, hWnd       : Integer;
  FileName         : array[0..4095] of Char;
  PE               : PE_File;

  DoBackUp         : boolean = true;
  DoReloc          : boolean = true;
  DoRelocDll       : boolean = false;
  DoOverlay        : boolean = false;
  DoWipe           : boolean = true;
  DoSave           : boolean = false;

const
  Copyright  = 'PE Optimizer v1.0 Your Name'  + #13#10 +
               'https://github.com'              + #13#10 + #13#10;

  OptionsKey = 'SOFTWARE\UinC\PEOptimizer\';


{ +---------------------------------------+ }
{ | Show dialog for inpet file selecting. | }
{ +---------------------------------------+ }
procedure SelectFile;
const
  Filter = 'Any PE File (*.exe,*.scr,*.dll,*.ocx)'#0'*.exe;*.scr;*.dll;*.ocx'#0+
           'Any File (*.*)'#0'*.*'#0#0;
  Title  = 'Open PE File for Optimization...';
var
  OpenFile : TOpenFileName;
begin
  FillChar(OpenFile, SizeOf(TOpenFileName), 0);

  with OpenFile do begin
    lStructSize  := SizeOf(TOpenFileName);
    hInstance    := Inst;
    hWndOwner    := hWnd;
    lpstrFilter  := Filter;
    nFilterIndex := 3;
    nMaxFile     := SizeOf(FileName);
    lpstrFile    := FileName;
    lpstrTitle   := Title;
    Flags        := OFN_LONGNAMES or OFN_EXPLORER or OFN_FILEMUSTEXIST or
                    OFN_PATHMUSTEXIST or OFN_HIDEREADONLY;

    if GetOpenFileNameA(OpenFile) = true then begin
      SetDlgItemText(hWnd, FILE_EDIT, lpstrFile);
      GetDlgItemText(hWnd, FILE_EDIT, FileName, 4096);
    end;
  end;
end;

{ +---------------------------------+ }
{ | Read options from checkboxes.   | }
{ +---------------------------------+ }
procedure GetOptions;
begin
  if SendDlgItemMessage(hWnd, BACKUP_BOX, BM_GETCHECK, 0, 0) = 1 then
    DoBackUp := true else DoBackUp := false;
  if SendDlgItemMessage(hWnd, RELOC_BOX, BM_GETCHECK, 0, 0) = 1 then
    DoReloc := true else DoReloc := false;
  if SendDlgItemMessage(hWnd, RELOCDLL_BOX, BM_GETCHECK, 0, 0) = 1 then
    DoRelocDll := true else DoRelocDll := false;
  if SendDlgItemMessage(hWnd, OVERLAY_BOX, BM_GETCHECK, 0, 0) = 1 then
    DoOverlay := true else DoOverlay := false;
  if SendDlgItemMessage(hWnd, WIPE_BOX, BM_GETCHECK, 0, 0) = 1 then
    DoWipe := true else DoWipe := false;
  if SendDlgItemMessage(hWnd, SAVE_BOX, BM_GETCHECK, 0, 0) = 1 then
    DoSave := true else DoSave := false;
end;

{ +---------------------------------+ }
{ | Apply options to checkboxes.    | }
{ +---------------------------------+ }
procedure SetOptions;
begin
  SendDlgItemMessage(hWnd, BACKUP_BOX, BM_SETCHECK, DWord(DoBackUp), 0);
  SendDlgItemMessage(hWnd, RELOC_BOX, BM_SETCHECK, DWord(DoReloc), 0);
  SendDlgItemMessage(hWnd, RELOCDLL_BOX, BM_SETCHECK, DWord(DoRelocDll), 0);
  SendDlgItemMessage(hWnd, OVERLAY_BOX, BM_SETCHECK, DWord(DoOverlay), 0);
  SendDlgItemMessage(hWnd, WIPE_BOX, BM_SETCHECK, DWord(DoWipe), 0);
  SendDlgItemMessage(hWnd, SAVE_BOX, BM_SETCHECK, DWord(DoSave), 0);
end;

{ +------------------------------------+ }
{ | Save options to registry.          | }
{ +------------------------------------+ }
procedure SaveOptions;
var
  Key     : HKEY;
  Res     : DWord;
  Options : array[1..5] of boolean;
begin
  GetOptions;
  RegCreateKeyEx(HKEY_LOCAL_MACHINE, OptionsKey, 0, nil,
    REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, nil, Key, @Res);
  Options[1] := DoBackUp;
  Options[2] := DoReloc;
  Options[3] := DoRelocDll;
  Options[4] := DoWipe;
  Options[5] := DoOverlay;
  RegSetValueEx(Key, '', 0, REG_BINARY, @Options, SizeOf(Options));
  RegCloseKey(Key);
end;

{ +------------------------------------+ }
{ | Load options from registry.        | }
{ +------------------------------------+ }
procedure LoadOptions;
var
  Key     : HKEY;
  Res1    : DWord;
  Res2    : DWord;
  Options : array[1..5] of boolean;
begin
  RegCreateKeyEx(HKEY_LOCAL_MACHINE, OptionsKey, 0, nil,
    REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, nil, Key, @Res1);
  if Res1 = REG_CREATED_NEW_KEY then Exit;
  if (RegQueryValueEx(Key, '', nil, @Res1, @Options, @Res2) <> ERROR_SUCCESS)or
     (Res1 <> REG_BINARY) then Exit;
  RegCloseKey(Key);
  DoBackUp   := Options[1];
  DoReloc    := Options[2];
  DoRelocDll := Options[3];
  DoWipe     := Options[4];
  DoOverlay  := Options[5];
  SetOptions;
end;

{ +--------------------------------+ }
{ | Create bacup copy of file.     | }
{ +--------------------------------+ }
function MakeBackUp : boolean;
var
  FindData : _WIN32_FIND_DATAA;
begin
  Result := false;
  if (DoBackUp = false) or (String(FileName) = '') then Exit;

  if FindFirstFile(PChar(String(FileName) + '.bak'), FindData) <>
     INVALID_HANDLE_VALUE then
  begin
    if MessageBox(hWnd, PChar('Owerwrite existing ' + String(FileName)+'.bak'+
                  ' ?!?!?!'),'Warning...',MB_OKCANCEL or MB_ICONWARNING)= IDOK
    then begin
      CopyFile(FileName, PChar(String(FileName) + '.bak'), false);
      Result := true;
    end;
  end else begin
    CopyFile(FileName, PChar(String(FileName) + '.bak'), false);
    Result := true;
  end;
end;

{ +--------------------------------------------+ }
{ | Restore backup file to its original name.  | }
{ +--------------------------------------------+ }
procedure RestoreBackUp;
begin
  MoveFileEx(PChar(String(FileName) + '.bak'), FileName,
    MOVEFILE_REPLACE_EXISTING);
end;

{ +------------------------------------+ }
{ | Add string with CF to INFO_EDIT.   | }
{ +------------------------------------+ }
procedure AddInfo(Info: String);
var
  OldInfo : array[0..65534] of Char;
begin
  GetDlgItemText(hWnd, INFO_EDIT, PChar(@OldInfo), 65535);
  SetDlgItemText(hWnd, INFO_EDIT, PChar(String(OldInfo) + Info));
end;

{ +------------------------------------+ }
{ | Optimize file.                     | }
{ +------------------------------------+ }
procedure ProcessFile;
var
  Info    : String;
  OrgSize : DWord;
  NewSize : DWord;
begin
  Info := '';
try
  AddInfo('Create BackUp... ');
  if MakeBackUp = true then Info := 'Ok.' else Info := 'Skipped.';
  AddInfo(Info + #13#10);

  AddInfo('Mapping input file... ');
  PE.LoadFromFile(String(FileName));
  case PE.LastError of
    E_OK             : Info := 'Ok.';
    E_FILE_NOT_FOUND : Info := 'Failed.' + #13#10#13#10 + 'File not found !!!' +
      'Aborting...';
    E_CANT_OPEN_FILE : Info := 'Failed.' + #13#10#13#10 + 'Can''t open file !!!'
      + ' Sharing violation ??? Aborting...';
    E_ERROR_READING  : Info := 'Failed.' + #13#10#13#10 +
      'Error reading file !!! Corrupt file ??? Aborting...';
    E_NOT_ENOUGHT_MEMORY : Info := 'Failed.' + #13#10#13#10 +
      'Not enought memory !!! Aborting...';
    E_INVALID_PE_FILE : Info := 'Failed.' + #13#10#13#10 +
      'Invalid PE structure, or non Win32 PE file !!! Aborting...';
  end;
  AddInfo(Info + #13#10);
  if (PE.LastError <> E_OK) then begin
    RestoreBackUp;
    Exit;
  end;

  OrgSize := PE.File_Size;

  AddInfo('Optimizing header... ');
  PE.OptimizeHeader(DoWipe);
  if PE.LastError = E_OK then Info := 'Ok.' else Info := 'Failed.';
  AddInfo(Info + #13#10);

  AddInfo('Flushing relocations... ');
  if DoReloc = false then Info := 'Skipped.'
  else begin
    PE.FlushRelocs(DoRelocDll);
    if (not DoRelocDll) and (PE.IsDLL) then Info := 'Skipped.'
    else Info := 'Ok.';
  end;
  AddInfo(Info + #13#10);

  AddInfo('Optimizing alignment... Ok.' + #13#10);
  PE.OptimizeFileAlignment;

  AddInfo('Clear file checksum... OK.' + #13#10);
  PE.FlushFileCheckSum;

  AddInfo('Write output file... ');
  PE.SaveToFile(String(FileName));
  case PE.LastError of
    E_OK             : Info := 'Ok.';
    E_CANT_OPEN_FILE : Info := 'Failed.' + #13#10#13#10 + 'Can''t open file !!!'
      + ' Sharing violation ??? Aborting...';
    E_ERROR_WRITING  : Info := 'Failed.' + #13#10 + 'Can''t write file ' +
      String(FileName) + ' !!! Aborting...';
  end;
  AddInfo(Info + #13#10);
  if (PE.LastError <> E_OK) then begin
    RestoreBackUp;
    Exit;
  end;

  NewSize := PE.File_Size;

  AddInfo('====================' + #13#10);
  Str(OrgSize, Info);
  AddInfo('Original  Size : ' + Info + #13#10);
  Str(NewSize, Info);
  AddInfo('Optimized Size : ' + Info + #13#10);
  Str(OrgSize - NewSize, Info);
  AddInfo('Saved          : ' + Info);;
  Str(Round(100 - (100 * NewSize) / OrgSize), Info);
  AddInfo(' (' + Info + '%).' + #13#10);
except
  AddInfo(#13#10#13#10'Fatal Unknown Internal Error !!! Aborting...'#13#10);
  RestoreBackUp;
end;

end;

procedure DoWork;
begin
  GetOptions;
  SetDlgItemText(hWnd, INFO_EDIT, '');
  AddInfo(Copyright);
  if (String(FileName) = '') then begin
    AddInfo('Select file first !!! Aborting...' + #13#10);
    Exit;
  end;
  AddInfo('Optimizing ' + String(FileName) + #13#10 +
          '====================' + #13#10);
  PE.PreserveOverlay := DoOverlay;
  ProcessFile;
end;

procedure MainDlgInit;
var
  hIcon, hFont, I : Integer;
  TmpStr          : String;
begin
  hIcon := LoadIcon(Inst, PChar(MAIN_ICON));
  SendMessage(hWnd, WM_SETICON, ICON_SMALL, hIcon);
  SendMessage(hWnd, WM_SETICON, ICON_BIG,   hIcon);

  hFont := CreateFont(8, 0, 0, 0, 400, 0, 0, 0,
                      DEFAULT_CHARSET,OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,
                      DEFAULT_QUALITY, DEFAULT_PITCH, 'Terminal');
  if hFont <> 0 then SendDlgItemMessage(hWnd, INFO_EDIT, WM_SETFONT, hFont, 0);

  LoadOptions;
  SetOptions;

  if ParamCount > 0 then begin
    TmpStr := ParamStr(1);
    for I:= 1 to Length(TmpStr) do FileName[I-1]:=TmpStr[I];
    FileName[Length(TmpStr)] := #00;
    SetDlgItemText(hWnd, FILE_EDIT, FileName);
    DoWork;
  end;

end;

{ ######################## Dialog Functions. ############################### }

procedure EndWork;
begin
  EndDialog(hWnd, 0);
  PE.Free;
  GetOptions;
  if DoSave = true then SaveOptions;
  ExitProcess(0);
end;

function AboutDlgProc(hWin, uMsg, wParam, lParam : Integer) : Integer; stdcall;
begin
  Result := 0;
  if (uMsg = WM_DESTROY) or  (uMsg   = WM_CLOSE) or
    ((uMsg = WM_COMMAND) and (wParam = ABOUT_CLOSE_BUTTON))
  then EndDialog(hWin,0);
end;

function MainDlgProc(hWin, uMsg, wParam, lParam : Integer) : Integer; stdcall;
begin
  Result := 0;
  case uMsg of
    WM_COMMAND    : begin
                      if wParam = CLOSE_BUTTON then EndWork;
                      if wParam = PROCESS_BUTTON then DoWork;
                      if wParam = FILE_BUTTON then SelectFile;
                      if wParam = ABOUT_BUTTON then
                        DialogBoxParam(Inst, PChar(ABOUT_DIALOG), hWin,
                                       @AboutDlgProc, 0);

                    end;
    WM_INITDIALOG : begin
                      hWnd := hWin;
                      MainDlgInit;
                    end;
    WM_DESTROY,
    WM_CLOSE      : EndWork;
  end;
end;

{ ########################################################################## }

begin
  Inst := hInstance;
  PE := PE_File.Create;
  PE.ShowDebugMessages := false;
  DialogBoxParam(Inst, PChar(MAIN_DIALOG), 0, @MainDlgProc, 0);
end.


