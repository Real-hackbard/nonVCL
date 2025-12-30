{$I compilerswitches.inc}

program DelFileOnReboot;

uses
  windows,
  messages,
  CommCtrl,
  constants in 'units\constants.pas',
  MpuAboutWnd in 'units\MpuAboutWnd.pas',
  MpuTools in 'units\MpuTools.pas';

{$R .\res\resource.res}

type
  TMpuDialog = class(TObject)
  private
    FHandle: THandle;  // Main dialog handle
    FDlgFuncPtr: Pointer;  // Funtion pointer
    FDlgTitle: WideString;  // Dialog caption
    FhDlgIcon: THandle;  // Dialog icon
    FLogFont: TLogFont;  // Font handle
    FhBannerFont: THandle;  // Font handle for banner font
    function MakeProcInstance(M: TMethod): Pointer;
    function DlgFunc(hDlg: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;
    // Getters / Setters
    function GethApp: THandle;
    function GetDlgTitle: WideString;
    procedure SetDlgTitle(Value: WideString);
    function GetIcon: THandle;
    procedure SetIcon(Value: THandle);
    // Internal methodes
    function Run: Integer;
    procedure Close;
    procedure SetDlgCaption;
    procedure SetBannerCaption;
    procedure SetDlgIcon;
    // Event handlers
    function OnInitDialog(hDlg: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): Boolean;
    function OnWMSize(wParam: WPARAM; lParam: LPARAM): Boolean;
    function OnCommand(wParam: WPARAM; lParam: LPARAM): Boolean;
    procedure OnClose(ExitCode: Integer = 0);
    procedure OnAddFiles;
    procedure OnDelFile;
    procedure OnOK;
    function DelFileOnReboot(Filename: String): Boolean;
  public
    destructor Destroy; override;
    property Handle: THandle read GethApp;
    property AppTitle: WideString read GetDlgTitle write SetdlgTitle;
    property Icon: THandle read GetIcon write SetIcon;
  end;

{$I tools.inc}

function TMpuDialog.DelFileOnReboot(Filename: String): Boolean;
begin
  Result := MoveFileEx(PChar(Filename), nil, MOVEFILE_DELAY_UNTIL_REBOOT);
end;

destructor TMpuDialog.Destroy;
begin
  if FhDlgIcon <> 0 then
    DestroyIcon(FhDlgIcon);
  if FhBannerFont <> 0 then
    DeleteObject(FhBannerFont);
  inherited;
end;

function TMpuDialog.Run: Integer;
var
  Method            : TMethod;
  msg               : TMsg;
begin
  InitCommonControls;
  Method.Code := @TMpuDialog.DlgFunc;
  Method.Data := Self;
  FDlgFuncPtr := MakeProcInstance(Method);
  CreateDialog(hInstance, MAKEINTRESOURCE(100), 0, FDlgFuncPtr);
  while true do
  begin
    if not GetMessage(msg, 0, 0, 0) then
      break;
    // it is no dialog message, go ahead
    if IsDialogMessage(Self.Handle, msg) = FALSE then
    begin
      TranslateMessage(msg);
      DispatchMessage(msg);
    end;
  end;
  Result := msg.wParam;
end;

procedure TMpuDialog.Close;
begin
  SendMessage(Handle, WM_CLOSE, 0, 0);
end;

function TMpuDialog.MakeProcInstance(M: TMethod): Pointer;
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

procedure TMpuDialog.SetDlgCaption;
begin
  SetWindowTextW(Self.Handle, PWideChar(AppTitle));
end;

procedure TMpuDialog.SetBannerCaption;
begin
  SetDlgItemTextW(Self.Handle, IDC_STC_BANNER, PWideChar(AppTitle));
end;

procedure TMpuDialog.SetDlgIcon;
begin
  if SendMessage(Self.Handle, WM_SETICON, ICON_SMALL, FhDlgIcon) = 0 then
    SendMessage(Self.Handle, WM_SETICON, ICON_BIG, FhDlgIcon);
end;

///////////////////////////////////////////////////////////////////////////////
// Getters / Setters
///////////////////////////////////////////////////////////////////////////////

function TMpuDialog.GethApp: THandle;
begin
  Result := FHandle;
end;

function TMpuDialog.GetDlgTitle: WideString;
begin
  Result := FDlgTitle;
end;

procedure TMpuDialog.SetDlgTitle(Value: WideString);
begin
  FDlgTitle := Value;
end;

function TMpuDialog.GetIcon: THandle;
begin
  Result := FhDlgIcon;
end;

procedure TMpuDialog.SetIcon(Value: THandle);
begin
  FhDlgIcon := Value;
end;

///////////////////////////////////////////////////////////////////////////////
// Event handlers
///////////////////////////////////////////////////////////////////////////////

function TMpuDialog.OnInitDialog(hDlg: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): Boolean;
var
  i                 : Integer;
begin
  SetDlgCaption;
  SetBannerCaption;
  SetDlgIcon;

  // Create and set the banner font
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
    for i := IDC_BTN_ABOUT to IDC_BTN_DELFILE do
      AddToolTip(hDlg, i, @ti, TOOLTIPS[i - IDC_BTN_ABOUT]);
  end;

  EnableWindow(getDlgItem(Handle, IDC_BTN_DELFILE), False);
  EnableWindow(getDlgItem(Handle, IDC_BTN_CLOSE), False);

  Result := True;
end;

procedure TMpuDialog.OnOK;
var
  cntItems: Integer;
  i: Integer;
  Item: array[0..MAX_PATH] of Char;
begin
  cntItems := SendDlgItemMessage(Handle, IDC_LST_FILES, LB_GETCOUNT, 0 ,0);
  if cntItems > 0 then
  begin
    for i := 0 to cntItems - 1 do
    begin
      SendDlgItemMessage(Handle, IDC_LST_FILES, LB_GETTEXT, i, Integer(@Item));
      DelFileOnReboot(String(Item));
    end;
  end;
  Close;
end;

function TMpuDialog.OnWMSize(wParam: WPARAM; lParam: LPARAM): Boolean;
var
  Panels            : array[0..1] of Integer;
begin
  // Resize and position banner elements
  MoveWindow(GetDlgItem(Self.Handle, IDC_STC_BANNER), 0, 0, loword(lParam), 75, TRUE);
  // SetDlgItemText(hApp, IDC_STC_BANNER, pointer(s));
  SetWindowPos(GetDlgItem(Self.Handle, IDC_BTN_ABOUT), GetDlgItem(Self.Handle, IDC_STC_BANNER), loword(lParam) - 47, 7,
    40, 22, 0);
  MoveWindow(GetDlgItem(Self.Handle, IDC_STC_DEVIDER), 0, 75, loword(lParam), 2, True);
  // Client area controls
  MoveWindow(GetDlgItem(Self.Handle, IDC_BTN_CLOSE), loword(lParam) - 95, hiword(lParam) - 55, 85, 24, TRUE);
  SetWindowPos(GetDlgItem(Self.Handle, IDC_SB), 0, 0, hiword(lParam) - 22, loword(lParam), 0, SWP_SHOWWINDOW);
  Panels[0] := loword(lParam) - 70;
  Panels[1] := -1;
  SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETPARTS, 2, Integer(@Panels));
  SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 1, Integer(PChar(TAboutWnd.GetFileVersion(ParamStr(0)))));
  // Force window to be redrawn
  InvalidateRect(Self.Handle, nil, False);
  RedrawWindow(Self.Handle, nil, 0, RDW_UPDATENOW);
  Result := True;
end;

function TMpuDialog.OnCommand(wParam: WPARAM; lParam: LPARAM): Boolean;
begin
  Result := True;
  // accel for closing the dialog with ESC
  if wParam = ID_CANCEL then
    OnClose;
  // Button clicks
  if hiword(wParam) = BN_CLICKED then
  begin
    case LoWord(wParam) of
      IDC_BTN_ABOUT: TAboutWnd.MsgBox(Self.Handle, 1);
      IDC_BTN_CLOSE: OnOK;
      IDC_BTN_ADDFILES: OnAddFiles;
      IDC_BTN_DELFILE: OnDelFile;
    end
  end;
end;

procedure TMpuDialog.OnDelFile;
var
  cntItems: Integer;
  SelectedItem: Integer;
begin
  cntItems := SendDlgItemMessage(Handle, IDC_LST_FILES, LB_GETCOUNT, 0, 0);
  if cntItems > 0 then
  begin
    SelectedItem := SendDlgItemMessage(Handle, IDC_LST_FILES, LB_GETCURSEL, 0, 0);
    if SelectedItem >= 0 then
    begin
      SendDlgItemMessage(Handle, IDC_LST_FILES, LB_DELETESTRING, SelectedItem, 0);
    end
    else
      MessageBox(Handle, PChar('No item selected'), PChar(String(AppTitle)), MB_ICONINFORMATION);
  end;
  cntItems := SendDlgItemMessage(Handle, IDC_LST_FILES, LB_GETCOUNT, 0, 0);
  EnableWindow(getDlgItem(Handle, IDC_BTN_DELFILE), cntItems <> 0);
  EnableWindow(GetDlgItem(Handle, IDC_BTN_CLOSE), cntItems <> 0);
end;

procedure TMpuDialog.OnAddFiles;
var
  Filename: String;
begin
  Filename := OpenFile(Handle, '');
  if Filename <> '' then
  begin
    SendDlgItemMessage(Handle, IDC_LST_FILES, LB_ADDSTRING, 0, Integer(@Filename[1]));
    EnableWindow(getDlgItem(Handle, IDC_BTN_DELFILE), True);
    EnableWindow(getDlgItem(Handle, IDC_BTN_CLOSE), True);
  end;
end;

procedure TMpuDialog.OnClose(ExitCode: Integer = 0);
begin
  DestroyWindow(Self.Handle);
  PostQuitMessage(ExitCode);
end;

function TMpuDialog.DlgFunc(hDlg: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;
begin
  FHandle := hDlg;
  Result := true;
  case uMsg of
    WM_INITDIALOG:
      begin
        Result := OnInitDialog(hDlg, uMsg, wParam, lParam);
      end;
    WM_SIZE: Result := OnWMSize(wParam, lParam);
    WM_CTLCOLORSTATIC:
      begin
        case GetDlgCtrlId(lParam) of
          IDC_STC_BANNER: // Color the banner white
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
        Result := OnCommand(wParam, lParam);
      end
  else
    Result := False;
  end;
end;

var
  MpuDialog         : TMpuDialog;

begin
  MpuDialog := TMpuDialog.Create;
  try
    MpuDialog.AppTitle := TAboutWnd.GetFileInfo(ParamStr(0), 'ProductName');
    MpuDialog.Icon := LoadImage(HInstance, MAKEINTRESOURCE(1), IMAGE_ICON, 16, 16, LR_DEFAULTCOLOR);
    ExitCode := MpuDialog.Run;
  finally
    MpuDialog.Free;
  end;
end.
