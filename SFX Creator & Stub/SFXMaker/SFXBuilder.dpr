{$I CompilerSwitches.inc}

program SFXBuilder;

uses
  windows,
  messages,
  CommCtrl,
  ShellAPI,
  constants in 'units\constants.pas',
  MpuAboutWnd in '..\Shared\MpuAboutWnd.pas',
  FileContainerCls in '..\Shared\FileContainerCls.pas',
  List in '..\Shared\List.pas',
  Exceptions in '..\Shared\Exceptions.pas',
  MpuTools in '..\Shared\MpuTools.pas',
  MpuDriveTools in 'units\MpuDriveTools.pas',
  SFXCls in '..\Shared\SFXCls.pas',
  BrowseForFolderCls in '..\Shared\BrowseForFolderCls.pas';

{$R .\res\resource.res}

type
  TSFXBuilder = class(TObject)
  private
    FHandle: THandle;
    FhAccelTbl: THandle;
    FDlgFuncPtr: Pointer;
    FMsg: UINT;
    FwParam: WPARAM;
    FlParam: LPARAM;
    FAppTitle: WideString;
    FhDlgIcon: THandle;
    FLogFont: TLogFont;
    FhBannerFont: THandle;
    FhImgSm: HIMAGELIST;
    //
    FFileList: TFileContainer;
    FCancel: Boolean;
    function MakeProcInstance(M: TMethod): Pointer;
    function DlgFunc(hDlg: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;
    // Getters / Setters
    function GethApp: THandle;
    function GetAppTitle: WideString;
    procedure SetAppTitle(Value: WideString);
    function GetIcon: THandle;
    procedure SetIcon(Value: THandle);
    // Internal methodes
    function Run: Integer;
    procedure SetDlgCaption;
    procedure SetBannerCaption;
    procedure SetDlgIcon;
    procedure MakeColumns;
    function GetItemText(hParent: THandle; ID: Integer): string;
    // Event handlers
    function OnInitDialog(hDlg: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): Boolean;
    function OnWMSize(wParam: WPARAM; lParam: LPARAM): Boolean;
    function OnCommand: Boolean;
    procedure OnClose(ExitCode: Integer = 0);
    procedure OnDirEditChange;
    procedure OnArchiveEditChange;
    // SFX methodes and events
    procedure GetAllFiles(dir: string);
    procedure FillLV;
    procedure OnFileFound(Filename: PChar);
    procedure BuildSFXArchive(Root, Filename: string);
    procedure OnAppendTOC(Sender: TObject);
    procedure OnAppendFile(Sender: TObject; Index: Integer; FileObject: TFile);
    procedure OnAppendingFile(Sender: TObject; FileObject: TFile; PercentDone: Integer);
  public
    destructor Destroy; override;
    property Handle: THandle read GethApp;
    property AppTitle: WideString read GetAppTitle write SetAppTitle;
    property Icon: THandle read GetIcon write SetIcon;
  end;

{$I tools.inc}

destructor TSFXBuilder.Destroy;
begin
  if FhDlgIcon <> 0 then
    DestroyIcon(FhDlgIcon);
  if FhBannerFont <> 0 then
    DeleteObject(FhBannerFont);
  inherited;
end;

////////////////////////////////////////////////////////////////////////////////
// Procedure : TSFXBuilder.Run
// Comment   :

function TSFXBuilder.Run: Integer;
var
  Method            : TMethod;
  msg               : TMsg;
begin
  InitCommonControls;
  Method.Code := @TSFXBuilder.DlgFunc;
  Method.Data := Self;
  FDlgFuncPtr := MakeProcInstance(Method);
  CreateDialog(hInstance, MAKEINTRESOURCE(100), 0, FDlgFuncPtr);
  FhAccelTbl := LoadAccelerators(hInstance, MAKEINTRESOURCE(PChar('IDR_ACCEL')));
  while true do
  begin
    if not GetMessage(msg, 0, 0, 0) then
      break;
    // no accel was pressed, go ahead
    if TranslateAccelerator(Self.Handle, FhAccelTbl, msg) = 0 then
      // it is no dialog message, go ahead
      if IsDialogMessage(Self.Handle, msg) = FALSE then
      begin
        TranslateMessage(msg);
        DispatchMessage(msg);
      end;
  end;
  Result := msg.wParam;
end;

////////////////////////////////////////////////////////////////////////////////
// Procedure : TSFXBuilder.MakeProcInstance
// Comment   : Push the self parameter onto the stack

function TSFXBuilder.MakeProcInstance(M: TMethod): Pointer;
begin
  // Ausführbaren Speicher alloziieren für 15 Byte an Code
  Result := VirtualAlloc(nil, 15, MEM_COMMIT, PAGE_EXECUTE_READWRITE);
  asm
    // MOV ECX,
    MOV BYTE PTR [EAX], $B9
    MOV ECX, M.Data
    MOV DWORD PTR [EAX+$1], ECX
    // POP EDX (bisherige Rücksprungadresse nach edx)
    MOV BYTE PTR [EAX+$5], $5A
    // PUSH ECX (self als Parameter 0 anfügen)
    MOV BYTE PTR [EAX+$6], $51
    // PUSH EDX (Rücksprungadresse zurück auf den Stack)
    MOV BYTE PTR [EAX+$7], $52
    // MOV ECX, (Adresse nach ecx laden)
    MOV BYTE PTR [EAX+$8], $B9
    MOV ECX, M.Code
    MOV DWORD PTR [EAX+$9], ECX
    // JMP ECX (Sprung an den ersten abgelegten Befehl und Methode aufrufen)
    MOV BYTE PTR [EAX+$D], $FF
    MOV BYTE PTR [EAX+$E], $E1
    // hier kein Call, ansonsten würde noch eine Rücksprungadresse auf den Stack gelegt
  end;
end;

///////////////////////////////////////////////////////////////////////////////
// Internal methodes
///////////////////////////////////////////////////////////////////////////////

procedure TSFXBuilder.SetDlgCaption;
begin
  SetWindowTextW(Self.Handle, PWideChar(AppTitle));
end;

procedure TSFXBuilder.SetBannerCaption;
begin
  SetDlgItemTextW(Self.Handle, IDC_STC_BANNER, PWideChar(AppTitle));
end;

procedure TSFXBuilder.SetDlgIcon;
begin
  if SendMessage(Self.Handle, WM_SETICON, ICON_SMALL, FhDlgIcon) = 0 then
    SendMessage(Self.Handle, WM_SETICON, ICON_BIG, FhDlgIcon);
end;

function TSFXBuilder.GetItemText(hParent: THandle; ID: Integer): string;
var
  p                 : PWideChar;
  len               : Integer;
  s                 : string;
begin
  p := nil;
  s := '';
  len := SendDlgItemMessage(hParent, ID, WM_GETTEXTLENGTH, 0, 0);
  if len > 0 then
  begin
    try
      p := GetMemory(len * 2 + 1);
      if Assigned(p) then
      begin
        GetDlgItemTextW(hParent, ID, p, len + 1);
        s := string(p);
      end;
    finally
      FreeMemory(p);
    end;
  end;
  result := s;
end;

///////////////////////////////////////////////////////////////////////////////
// Getters / Setters
///////////////////////////////////////////////////////////////////////////////

function TSFXBuilder.GethApp: THandle;
begin
  Result := FHandle;
end;

function TSFXBuilder.GetAppTitle: WideString;
begin
  Result := FAppTitle;
end;

procedure TSFXBuilder.SetAppTitle(Value: WideString);
begin
  FAppTitle := Value;
end;

function TSFXBuilder.GetIcon: THandle;
begin
  Result := FhDlgIcon;
end;

procedure TSFXBuilder.SetIcon(Value: THandle);
begin
  FhDlgIcon := Value;
end;

procedure TSFXBuilder.MakeColumns;
var
  i                 : Integer;
  lvc               : TLVColumn;
begin
  ZeroMemory(@lvc, SizeOf(TLVColumn));
  lvc.mask := LVCF_TEXT or LVCF_WIDTH or LVCF_FMT;
  for i := 0 to length(COLS) - 1 do
  begin
    lvc.pszText := PChar(COLS[i]);
    case i of
      0: lvc.cx := 350;
      1:
        begin
          lvc.cx := 75;
          lvc.fmt := LVCFMT_RIGHT;
        end;
    end;
    SendMessage(GetDlgItem(Handle, IDC_LV_FILES), LVM_INSERTCOLUMN, i, Integer(@lvc));
  end;
end;

///////////////////////////////////////////////////////////////////////////////

procedure TSFXBuilder.FillLV;
var
  i                 : Integer;
  lvi               : TLVItem;
  fi                : TSHFileInfo;
  s                 : string;

  function StripRoot(Root, Filepath: string): string;
  var
    s               : string;
  begin
    s := FilePath;
    Delete(s, 1, length(Root));
    Result := s;
  end;

begin
  SendDlgItemMessage(Handle, IDC_LV_FILES, WM_SETREDRAW, 0, 0);
  ZeroMemory(@lvi, SizeOf(TLVItem));
  lvi.mask := LVIF_TEXT or LVIF_IMAGE;
  for i := 0 to FFileList.Count - 1 do
  begin
    SHGetFileInfo(PChar(FFileList.Items[i].Filename), 0, fi, sizeof(TSHFileInfo), SHGFI_ICON or SHGFI_SYSICONINDEX or
      SHGFI_TYPENAME);
    lvi.iItem := i;
    lvi.iSubItem := 0;
    lvi.iImage := fi.iIcon;
    lvi.pszText := PChar(StripRoot(GetItemText(Handle, IDC_EDT_DIR), FFileList.Items[i].Filename));
    SendDlgItemMessage(Handle, IDC_LV_FILES, LVM_INSERTITEM, 0, Integer(@lvi));
    lvi.iSubItem := 1;
    lvi.pszText := PChar(IntToStr(FFileList.Items[i].FileSize));
    SendDlgItemMessage(Handle, IDC_LV_FILES, LVM_SETITEM, 0, Integer(@lvi));
    lvi.iSubItem := 2;
    lvi.pszText := PChar(IntToStr(FFileList.Items[i].OffSet));
    SendDlgItemMessage(Handle, IDC_LV_FILES, LVM_SETITEM, 0, Integer(@lvi));
    SendDlgItemMessage(Handle, IDC_LV_Files, LVM_ENSUREVISIBLE, i, Integer(False));
    s := Format(rsOnFillLV, [i * 100 div FFileList.Count]);
    SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 0, Integer(PChar(s)));
    SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 1, Integer(nil));
    ProcessMessages(Handle);
  end;
  SendDlgItemMessage(Handle, IDC_LV_Files, LVM_ENSUREVISIBLE, 0, Integer(False));
  s := Format(rsOnFileFound, [FFileList.Count]);
  SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 0, Integer(PChar(s)));
  s := rsOnFileFoundTotalFileSize + IntToStr(FFileList.TotalSize div 1024) + ' KBytes';
  SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 1, Integer(PChar(s)));
  SendDlgItemMessage(Handle, IDC_LV_FILES, WM_SETREDRAW, 1, 0);
end;

procedure TSFXBuilder.OnFileFound(Filename: PChar);
var
  FileObject        : TFile;
  s                 : string;
begin
  FileObject := TFile.Create;
  FileObject.Filename := Filename;
  FileObject.FileSize := GetFileSize(Filename);
  FFileList.Add(FileObject);
  s := Format(rsOnFileFound, [FFileList.Count]);
  SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 0, Integer(PChar(s)));
  s := rsOnFileFoundTotalFileSize + IntToStr(FFileList.TotalSize div 1024) + ' KBytes';
  SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 1, Integer(PChar(s)));
  ProcessMessages(Handle);
end;

procedure TSFXBuilder.GetAllFiles(dir: string);
var
  FindFiles         : TFindFiles;
begin
  FFileList.Clear;
  ListView_DeleteAllItems(GetDlgItem(Handle, IDC_LV_FILES));
  SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 0, Integer(nil));
  SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 1, Integer(nil));
  FindFiles := TFindFiles.Create(Handle, Dir, '*.*', True, False);
  FindFiles.FindFiles;
end;

procedure TSFXBuilder.BuildSFXArchive(Root, Filename: string);
var
  SFX               : TSFX;
  s                 : string;
begin
  SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 0, Integer(nil));
  SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 1, Integer(nil));
  SFX := TSFX.Create(Filename, Root, FFileList);
  try
    SFX.OnAppendTOC := OnAppendTOC;
    SFX.OnAppendFile := OnAppendFile;
    SFX.OnAppendingFile := OnAppendingFile;
    try
      SFX.CopyStub(ExtractFilepath(ParamStr(0)) + 'SFXStub.exe', Filename);
      SFX.AppendFiles;
      SFX.AppendTOC;
    except
      on E: Exception do
      begin
        MessageBoxW(Handle, PWideChar(E.Message), 'SFX Error', MB_ICONSTOP);
        EnableControl(Handle, IDC_BTN_SAVEAS, True);
        EnableControl(Handle, IDC_EDT_ARCHIVE, True);
        EnableControl(Handle, IDC_BTN_BUILD, True);
      end;
    end;
  finally
    SFX.Free;
    s := rsFinish;
    SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 0, Integer(PChar(s)));
    SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 1, Integer(nil));
    SendDlgItemMessage(Handle, IDC_PB, PBM_SETPOS, 0, 0);
    EnableControl(Handle, IDC_BTN_SELDIR, True);
    EnableControl(Handle, IDC_EDT_DIR, True);
    EnableControl(Handle, IDC_BTN_GETFILES, True);
    EnableControl(Handle, IDC_BTN_SAVEAS, True);
    EnableControl(Handle, IDC_EDT_ARCHIVE, True);
    EnableControl(Handle, IDC_BTN_BUILD, True);
  end;
end;

procedure TSFXBuilder.OnAppendFile(Sender: TObject; Index: Integer; FileObject: TFile);
var
  s                 : string;
begin
  s := Format(rsOnAppendFile, [Index + 1, FFileList.Count]);
  SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 0, Integer(PChar(s)));
end;

procedure TSFXBuilder.OnAppendingFile(Sender: TObject; FileObject: TFile; PercentDone: Integer);
begin
  SendDlgItemMessage(Handle, IDC_PB, PBM_SETPOS, PercentDone, 0);
  ProcessMessages(Handle);
end;

procedure TSFXBuilder.OnAppendTOC(Sender: TObject);
var
  s                 : string;
begin
  s := rsOnAppendTOC;
  SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 0, Integer(PChar(s)));
  SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 1, Integer(nil));
end;

///////////////////////////////////////////////////////////////////////////////
// Event handlers
///////////////////////////////////////////////////////////////////////////////

function TSFXBuilder.OnInitDialog(hDlg: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): Boolean;
var
  i                 : Integer;
  fi                : TSHFileInfo;
begin
  SetDlgCaption;
  SetBannerCaption;
  SetDlgIcon;

  FLogFont := GetSystemFont;
  FLogFont.lfHeight := BANNERFONTSIZE;
  FLOgFont.lfWeight := 900;
  FhBannerFont := CreateFontIndirect(FLogFont);
  if FhBannerFont <> 0 then
  begin
    SendDlgItemMessage(hDlg, IDC_STC_BANNER, WM_SETFONT, Integer(FhBannerFont), Integer(true));
  end;

  // Tooltips
  if CreateToolTips(Self.Handle) then
  begin
    for i := IDC_BTN_ABOUT to IDC_BTN_GETFILES do
      AddToolTip(hDlg, i, @ti, TOOLTIPS[i - IDC_BTN_ABOUT]);
  end;

  MakeColumns;
  ListView_SetExtendedListViewStyle(GetDlgItem(Handle, IDC_LV_FILES), LVS_EX_FULLROWSELECT or LVS_EX_INFOTIP);

  ZeroMemory(@fi, sizeof(TSHFileInfo));
  FhImgSm := HIMAGELIST(SHGetFileInfo('', 0, fi, sizeof(fi),
    SHGFI_SYSICONINDEX or SHGFI_SMALLICON));
  if (FhImgSm <> 0) then
    ListView_SetImageList(GetDlgItem(Handle, IDC_LV_FILES), FhImgSm, LVSIL_SMALL);

  SendDlgItemMessage(Handle, IDC_PB, PBM_SETRANGE32, 0, 100);

  EnableControl(Handle, IDC_BTN_GETFILES, False);
  EnableControl(Handle, IDC_EDT_ARCHIVE, False);
  EnableControl(Handle, IDC_BTN_SAVEAS, False);
  EnableControl(Handle, IDC_EDT_ARCHIVE, False);
  EnableControl(Handle, IDC_BTN_BUILD, False);

  FFileList := TFileContainer.Create;
  Result := True;
end;

function TSFXBuilder.OnWMSize(wParam: WPARAM; lParam: LPARAM): Boolean;
var
  Panels            : array[0..2] of Integer;
begin
  // Resize and position banner elements
  MoveWindow(GetDlgItem(Self.Handle, IDC_STC_BANNER), 0, 0, loword(lParam), 75, TRUE);
  // SetDlgItemText(hApp, IDC_STC_BANNER, pointer(s));
  SetWindowPos(GetDlgItem(Self.Handle, IDC_BTN_ABOUT), GetDlgItem(Self.Handle, IDC_STC_BANNER), loword(lParam) - 47, 7,
    40, 22, 0);
  MoveWindow(GetDlgItem(Self.Handle, IDC_STC_DEVIDER), 0, 74, loword(lParam), 2, True);
  // Client area controls
  SetWindowPos(GetDlgItem(Self.Handle, IDC_SB), 0, 0, hiword(lParam) - 22, loword(lParam), 0, SWP_SHOWWINDOW);

  Panels[0] := 200;
  Panels[1] := 400;
  Panels[2] := -1;
  SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETPARTS, 3, Integer(@Panels));
  SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 2, Integer(PChar(TAboutWnd.GetFileVersion(ParamStr(0)))));
  SetWindowPos(GetDlgItem(Handle, IDC_SB), HWND_BOTTOM, 0, 0, 0, 0, SWP_SHOWWINDOW or SWP_NOSIZE or SWP_NOMOVE);

  // Force window to be redrawn
  InvalidateRect(Self.Handle, nil, False);
  RedrawWindow(Self.Handle, nil, 0, RDW_UPDATENOW);

  SetFocus(GetDlgItem(Handle, IDC_EDT_DIR));
  Result := True;
end;

procedure TSFXBuilder.OnDirEditChange;
var
  dir               : string;
begin
  dir := GetItemText(Handle, IDC_EDT_DIR);
  EnableControl(Handle, IDC_BTN_GETFILES, DirectoryExists(dir));

end;

procedure TSFXBuilder.OnArchiveEditChange;
var
  Filename          : string;
begin
  Filename := GetItemText(Handle, IDC_EDT_ARCHIVE);
  EnableControl(Handle, IDC_BTN_BUILD, Filename <> '');
end;

function TSFXBuilder.OnCommand: Boolean;
var
  fb                : TFolderBrowser;
  dir               : string;
  Filename          : string;
begin
  Result := True;
  // accel for closing the dialog with ESC
  if FwParam = ID_CANCEL then
    OnClose;
  // EN_CHANGE
  if hiword(FwParam) = EN_CHANGE then
  begin
    case LoWord(FwParam) of
      IDC_EDT_DIR:
        begin
          OnDirEditChange;
          Exit;
        end;
      IDC_EDT_ARCHIVE:
        begin
          OnArchiveEditChange;
          Exit;
        end;
    end;
  end;
  // Button clicks
  if hiword(FwParam) = BN_CLICKED then
  begin
    case LoWord(FwParam) of
      IDC_BTN_ABOUT: TAboutWnd.MsgBox(Self.Handle, 1);
      IDC_BTN_SELDIR:
        begin
          fb := TFolderBrowser.Create(Handle, 'Select directory with files for archive');
          try
            if fb.Execute then
            begin
              dir := fb.SelectedItem;
              SetDlgItemText(Handle, IDC_EDT_DIR, PChar(dir));
            end;
          finally
            fb.Free;
          end;
        end;
      IDC_BTN_GETFILES:
        begin
          EnableControl(Handle, IDC_BTN_GETFILES, False);
          EnableControl(Handle, IDC_BTN_SELDIR, False);
          EnableControl(Handle, IDC_EDT_DIR, False);
          EnableControl(Handle, IDC_BTN_SAVEAS, False);
          EnableControl(Handle, IDC_BTN_BUILD, False);
          EnableControl(Handle, IDC_EDT_ARCHIVE, False);
          GetAllFiles(GetItemText(Handle, IDC_EDT_DIR));
        end;
      IDC_BTN_SAVEAS:
        begin
          Filename := SaveFileAs(Handle, '*.exe'#0'*.exe', 'exe');
          if Filename <> '' then
          begin
            SetDlgItemText(Handle, IDC_EDT_ARCHIVE, PChar(Filename));
          end;
        end;
      IDC_BTN_BUILD:
        begin
          FCancel := False;
          EnableControl(Handle, IDC_BTN_BUILD, False);
          EnableControl(Handle, IDC_BTN_GETFILES, False);
          EnableControl(Handle, IDC_BTN_SELDIR, False);
          EnableControl(Handle, IDC_EDT_DIR, False);
          EnableControl(Handle, IDC_EDT_ARCHIVE, False);
          EnableControl(Handle, IDC_BTN_SAVEAS, False);
          BuildSFXArchive(GetItemText(Handle, IDC_EDT_DIR), GetItemText(Handle, IDC_EDT_ARCHIVE));
        end;
    end
  end;
end;

procedure TSFXBuilder.OnClose(ExitCode: Integer = 0);
begin
  FFileList.Free;
  DestroyWindow(Self.Handle);
  PostQuitMessage(ExitCode);
end;

function TSFXBuilder.DlgFunc(hDlg: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;
begin
  FHandle := hDlg;
  FMsg := uMsg;
  FwParam := wParam;
  FlParam := lparam;
  Result := true;
  case uMsg of
    WM_INITDIALOG:
      begin
        Result := OnInitDialog(hDlg, uMsg, wParam, lParam);
      end;
    WM_GETMINMAXINFO:
      begin
        // limit window size
        PMinMaxInfo(lParam)^.ptMinTrackSize := Point(300, 250);
      end;
    WM_SIZE: Result := OnWMSize(wParam, lParam);
    WM_CTLCOLORSTATIC:
      begin
        case GetDlgCtrlId(lParam) of
          IDC_STC_BANNER: // color the banner white
            begin
              Result := BOOL(GetStockObject(WHITE_BRUSH));
            end;
        else
          Result := False;
        end;
      end;
    WM_LBUTTONDOWN:
      begin
        // Move the window with the left button down
        SetCursor(LoadCursor(0, IDC_SIZEALL));
        SendMessage(hDlg, WM_NCLBUTTONDOWN, HTCAPTION, lParam);
      end;
    WM_CLOSE:
      begin
        OnClose;
      end;
    WM_COMMAND:
      begin
        Result := OnCommand;
      end;
    FFM_ONFILEFOUND:
      begin
        OnFileFound(PChar(lParam));
      end;
    FFM_FINISH:
      begin
        EnableControl(Handle, IDC_BTN_GETFILES, True);
        EnableControl(Handle, IDC_BTN_SELDIR, True);
        EnableControl(Handle, IDC_EDT_DIR, True);
        if FFileList.Count > 0 then
        begin
          FillLV;
          EnableControl(Handle, IDC_EDT_ARCHIVE, True);
          EnableControl(Handle, IDC_BTN_SAVEAS, True);
        end;
      end;
  else
    Result := False;
  end;
end;

var
  MpuDialog         : TSFXBuilder;

begin
  MpuDialog := TSFXBuilder.Create;
  try
    MpuDialog.AppTitle := TAboutWnd.GetFileInfo(ParamStr(0), 'ProductName');
    MpuDialog.Icon := LoadImage(HInstance, MAKEINTRESOURCE(1), IMAGE_ICON, 16, 16, LR_DEFAULTCOLOR);
    ExitCode := MpuDialog.Run;
  finally
    MpuDialog.Free;
  end;
end.

