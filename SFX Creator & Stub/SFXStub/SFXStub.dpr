{$I CompilerSwitches.inc}

program SFXStub;

uses
  windows,
  messages,
  CommCtrl,
  ShellAPI,
  constants in 'units\constants.pas',
  MpuAboutWnd in '..\Shared\MpuAboutWnd.pas',
  MpuTools in '..\Shared\MpuTools.pas',
  SFXCls in '..\Shared\SFXCls.pas',
  Exceptions in '..\Shared\Exceptions.pas',
  FileContainerCls in '..\Shared\FileContainerCls.pas',
  List in '..\Shared\List.pas',
  BrowseForFolderCls in '..\Shared\BrowseForFolderCls.pas';

{$R .\res\resource.res}

type
  TSFXStub = class(TObject)
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
    FirstTime: Boolean;

    FFileList: TFileContainer;
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
    function GetItemText(hParent: THandle; ID: Integer): string;
    procedure MakeColumns;
    procedure FillLV;
    // SFX methodes and events
    procedure GetAttachedFiles;
    procedure ExtractFiles(Root: string);
    // Event handlers
    function OnInitDialog(hDlg: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): Boolean;
    function OnWMSize(wParam: WPARAM; lParam: LPARAM): Boolean;
    function OnCommand: Boolean;
    procedure OnClose(ExitCode: Integer = 0);
    procedure OnPaint(ps: TPaintStruct);
    procedure OnEditDirChange;
  public
    destructor Destroy; override;
    property Handle: THandle read GethApp;
    property AppTitle: WideString read GetAppTitle write SetAppTitle;
    property Icon: THandle read GetIcon write SetIcon;
    procedure OnExtractFile(Sender: TObject; Index: Integer; FileObject: TFile);
    procedure OnExttractingFile(Sender: TObject; FileObject: TFile; PercentDone: Integer);
  end;

{$I tools.inc}

destructor TSFXStub.Destroy;
begin
  if FhDlgIcon <> 0 then
    DestroyIcon(FhDlgIcon);
  if FhBannerFont <> 0 then
    DeleteObject(FhBannerFont);
  inherited;
end;

////////////////////////////////////////////////////////////////////////////////
// Procedure : TSFXStub.Run
// Comment   :

function TSFXStub.Run: Integer;
var
  Method            : TMethod;
  msg               : TMsg;
begin
  InitCommonControls;
  Method.Code := @TSFXStub.DlgFunc;
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
// Procedure : TSFXStub.MakeProcInstance
// Comment   : Push the self parameter onto the stack

function TSFXStub.MakeProcInstance(M: TMethod): Pointer;
begin
  // Allocate executable memory for 15 bytes of code
  Result := VirtualAlloc(nil, 15, MEM_COMMIT, PAGE_EXECUTE_READWRITE);
  asm
    // MOV ECX,
    MOV BYTE PTR [EAX], $B9
    MOV ECX, M.Data
    MOV DWORD PTR [EAX+$1], ECX
    // POP EDX (Previous return address to edx)
    MOV BYTE PTR [EAX+$5], $5A
    // PUSH ECX (Add self as parameter 0)
    MOV BYTE PTR [EAX+$6], $51
    // PUSH EDX (Return address back to the stack)
    MOV BYTE PTR [EAX+$7], $52
    // MOV ECX, (Load address to ecx)
    MOV BYTE PTR [EAX+$8], $B9
    MOV ECX, M.Code
    MOV DWORD PTR [EAX+$9], ECX
    // JMP ECX (Jump to the first stored command and call the method)
    MOV BYTE PTR [EAX+$D], $FF
    MOV BYTE PTR [EAX+$E], $E1
    // No call here, otherwise a return address would be placed on the stack.
  end;
end;

///////////////////////////////////////////////////////////////////////////////
// Internal methodes
///////////////////////////////////////////////////////////////////////////////

procedure TSFXStub.SetDlgCaption;
begin
  SetWindowTextW(Self.Handle, PWideChar(AppTitle));
end;

procedure TSFXStub.SetBannerCaption;
begin
  SetDlgItemTextW(Self.Handle, IDC_STC_BANNER, PWideChar(AppTitle));
end;

procedure TSFXStub.SetDlgIcon;
begin
  if SendMessage(Self.Handle, WM_SETICON, ICON_SMALL, FhDlgIcon) = 0 then
    SendMessage(Self.Handle, WM_SETICON, ICON_BIG, FhDlgIcon);
end;

function TSFXStub.GetItemText(hParent: THandle; ID: Integer): string;
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

function TSFXStub.GethApp: THandle;
begin
  Result := FHandle;
end;

function TSFXStub.GetAppTitle: WideString;
begin
  Result := FAppTitle;
end;

procedure TSFXStub.SetAppTitle(Value: WideString);
begin
  FAppTitle := Value;
end;

function TSFXStub.GetIcon: THandle;
begin
  Result := FhDlgIcon;
end;

procedure TSFXStub.SetIcon(Value: THandle);
begin
  FhDlgIcon := Value;
end;

procedure TSFXStub.MakeColumns;
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

procedure TSFXStub.FillLV;
var
  i                 : Integer;
  lvi               : TLVItem;
  fi                : TSHFileInfo;
begin
  SendDlgItemMessage(Handle, IDC_LV_FILES, WM_SETREDRAW, 0, 0);
  ZeroMemory(@lvi, SizeOf(TLVItem));
  lvi.mask := LVIF_TEXT or LVIF_IMAGE;
  for i := 0 to FFileList.Count - 1 do
  begin
    SHGetFileInfo(PChar(ExtractFilename(FFileList.Items[i].Filename)), 0, fi, sizeof(TSHFileInfo), SHGFI_ICON or
      SHGFI_SYSICONINDEX or SHGFI_USEFILEATTRIBUTES);
    lvi.iItem := i;
    lvi.iSubItem := 0;
    lvi.iImage := fi.iIcon;
    lvi.pszText := PChar(FFileList.Items[i].Filename);
    SendDlgItemMessage(Handle, IDC_LV_FILES, LVM_INSERTITEM, 0, Integer(@lvi));
    lvi.iSubItem := 1;
    lvi.pszText := PChar(IntToStr(FFileList.Items[i].FileSize));
    SendDlgItemMessage(Handle, IDC_LV_FILES, LVM_SETITEM, 0, Integer(@lvi));
    lvi.iSubItem := 2;
    lvi.pszText := PChar(IntToStr(FFileList.Items[i].OffSet));
    SendDlgItemMessage(Handle, IDC_LV_FILES, LVM_SETITEM, 0, Integer(@lvi));
  end;
  SendDlgItemMessage(Handle, IDC_LV_FILES, WM_SETREDRAW, 1, 0);
end;

///////////////////////////////////////////////////////////////////////////////
// SFX methodes and events
///////////////////////////////////////////////////////////////////////////////

procedure TSFXStub.GetAttachedFiles;
var
  SFX               : TSFX;
begin
  SFX := TSFX.Create(ParamStr(0), '', FFileList);
  try
    try
      SFX.ReadTOC;
    except
      on E: Exception do
        MessageBoxW(Handle, PWideChar(E.Message), 'SFX Error', MB_ICONSTOP);
    end
  finally
    SFX.Free;
  end;
end;

procedure TSFXStub.ExtractFiles(Root: string);
var
  SFX               : TSFX;
  s                 : string;
begin
  SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 1, Integer(nil));
  SFX := TSFX.Create(ParamStr(0), Root, FFileList);
  try
    SFX.OnExtractFile := OnExtractFile;
    SFX.OnExtractingFile := OnExttractingFile;
    try
      SFX.ExtractFiles;
    except
      on E: Exception do
        MessageBoxW(Handle, PWideChar(E.Message), 'SFX Error', MB_ICONSTOP);
    end;
  finally
    SFX.Free;
    s := rsFinish;
    SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 0, Integer(PChar(s)));
    SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 1, Integer(nil));
    SendDlgItemMessage(Self.Handle, IDC_PB, PBM_SETPOS, 0, 0);
  end;
end;

procedure TSFXStub.OnExtractFile(Sender: TObject; Index: Integer; FileObject: TFile);
var
  s                 : string;
begin
  s := Format(rsOnExtractFile, [Index + 1, FFileList.Count]);
  SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 0, Integer(PChar(s)));
end;

procedure TSFXStub.OnExttractingFile(Sender: TObject; FileObject: TFile; PercentDone: Integer);
begin
  SendDlgItemMessage(Self.Handle, IDC_PB, PBM_SETPOS, PercentDone, 0);
  ProcessMessages(Handle);
end;

///////////////////////////////////////////////////////////////////////////////
// Event handlers
///////////////////////////////////////////////////////////////////////////////

function TSFXStub.OnInitDialog(hDlg: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): Boolean;
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
    for i := IDC_BTN_ABOUT to IDC_BTN_EXTRACT do
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

  EnableControl(Handle, IDC_EDT_DIR, False);
  EnableControl(Handle, IDC_BTN_SELDIR, False);
  EnableControl(Handle, IDC_BTN_EXTRACT, False);

  FirstTime := True;
  Result := True;
end;

function TSFXStub.OnWMSize(wParam: WPARAM; lParam: LPARAM): Boolean;
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
  // Force window to be redrawn
  InvalidateRect(Self.Handle, nil, False);
  RedrawWindow(Self.Handle, nil, 0, RDW_UPDATENOW);
  Result := True;
end;

procedure TSFXStub.OnPaint(ps: TPaintStruct);
var
  s                 : string;
  TotalSize         : Int64;
  i                 : Integer;
begin
  if FirstTime then
  begin
    FirstTime := False;
    FFileList := TFileContainer.Create;
    GetAttachedFiles;
    if FFileList.Count > 0 then
    begin
      FillLV;
      s := Format(rsFilesInArchive, [FFileList.Count]);
      SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 0, Integer(PChar(s)));
      TotalSize := 0;
      for i := 0 to FFileList.Count - 1 do
      begin
        TotalSize := TotalSize + FFileList.Items[i].FileSize;
      end;
      s := 'Total size: ' + IntToStr(TotalSize div 1024) + ' KBytes';
      SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 1, Integer(PChar(s)));
      EnableControl(Handle, IDC_EDT_DIR, True);
      EnableControl(Handle, IDC_BTN_SELDIR, True);
    end;
  end;
end;

procedure TSFXStub.OnEditDirChange;
var
  dir: String;
begin
  dir := GetItemText(Handle, IDC_EDT_DIR);
  EnableControl(Handle, IDC_BTN_EXTRACT, dir <> '');
end;

function TSFXStub.OnCommand: Boolean;
var
  fb                : TFolderBrowser;
  dir               : string;
begin
  Result := True;
  // accel for closing the dialog with ESC
  if FwParam = ID_CANCEL then
    OnClose;
  if hiword(FwParam) = EN_CHANGE then
  begin
    case loword(FwParam) of
      IDC_EDT_DIR:
      begin
        OnEditDirChange;
        Exit;
      end;
    end;
  end;
  // Button clicks
  if hiword(FwParam) = BN_CLICKED then
  begin
    case LoWord(FwParam) of
      IDC_BTN_ABOUT: TAboutWnd.MsgBox(Self.Handle, 1, 'Created with SFXBuilder.');
      IDC_BTN_SELDIR:
        begin
          fb := TFolderBrowser.Create(Handle, 'Select destination directory');
          try
            fb.NewFolderButton := True;
            if fb.Execute then
            begin
              dir := fb.SelectedItem;
              SetDlgItemText(Handle, IDC_EDT_DIR, PChar(dir));
            end;
          finally
            fb.Free;
          end;
        end;
      IDC_BTN_EXTRACT: ExtractFiles(GetItemText(Handle, IDC_EDT_DIR));
    end
  end;
end;

procedure TSFXStub.OnClose(ExitCode: Integer = 0);
begin
  FFileList.Free;
  DestroyWindow(Self.Handle);
  PostQuitMessage(ExitCode);
end;

function TSFXStub.DlgFunc(hDlg: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;
var
  ps                : TPaintStruct;
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
    WM_PAINT:
      begin
        BeginPaint(Handle, ps);
        OnPaint(ps);
        EndPaint(Handle, ps);
      end;
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
      end
  else
    Result := False;
  end;
end;

var
  MpuDialog         : TSFXStub;

begin
  MpuDialog := TSFXStub.Create;
  try
    MpuDialog.AppTitle := TAboutWnd.GetFileInfo(ParamStr(0), 'ProductName');
    MpuDialog.Icon := LoadImage(HInstance, MAKEINTRESOURCE(1), IMAGE_ICON, 16, 16, LR_DEFAULTCOLOR);
    ExitCode := MpuDialog.Run;
  finally
    MpuDialog.Free;
  end;
end.

