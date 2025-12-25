{$I CompilerSwitches.inc}

program FileCrypter;

uses
{$IF USEFASTMM}
  FastMM4 in 'units\FastMM\FastMM4.pas',
  FastMM4Messages in 'units\FastMM\FastMM4Messages.pas',
{$IFEND}
  windows,
  messages,
  CommCtrl,
  ShellAPI,
  constants in 'units\constants.pas',
  MpuAboutWnd in 'units\MpuAboutWnd.pas',
  Encrypt in 'units\Encrypt.pas',
  MpuTools in 'units\MpuTools.pas',
  Exceptions in 'units\Exceptions.pas';

{$R .\res\resource.res}

type
  TMpuDialog = class(TObject)
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
    FPercentDoneOld: Integer;
    FAbort: Boolean;
    FOldAppTitle: string;
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
    procedure SetDlgCaption(Caption: WideString);
    procedure SetBannerCaption;
    procedure SetDlgIcon;
    // Event handlers
    function OnInitDialog(hDlg: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): Boolean;
    function OnWMSize(wParam: WPARAM; lParam: LPARAM): Boolean;
    function OnCommand: Boolean;
    procedure OnDropFiles(wParam: WPARAM; lParam: LPARAM);
    procedure OnClose(ExitCode: Integer = 0);

    procedure Encrypt(const InFilename, OutFilename: string; const Pwd: string);
    procedure Decrypt(const InFilename, OutFilename: string; const Pwd: string);
    procedure OnProgress(Sender: TObject; PercentDone: Integer);
    procedure OnShredderStart(Sender: TObject);
    procedure OnShredderProgress(Sender: TObject; PercentDone: Cardinal);
    procedure OnShredderFinish(Sender: TObject);
    procedure OnShredderPass(Sender: TObject; Pass: Cardinal; PassCount: Cardinal);
  public
    destructor Destroy; override;
    property Handle: THandle read GethApp;
    property AppTitle: WideString read GetAppTitle write SetAppTitle;
    property Icon: THandle read GetIcon write SetIcon;
  end;

{$I tools.inc}

function GetItemText(hDlg: THandle; ID: DWORD): string;
var
  buffer            : array[0..255] of Char;
begin
  ZeroMemory(@buffer, Length(buffer));
  GetDlgItemText(hDlg, ID, buffer, Length(buffer));
  Result := string(buffer);
end;

function GetDlgBtnCheck(hParent: THandle; ID: Integer): Boolean;
begin
  result := IsDlgButtonChecked(hParent, ID) = BST_CHECKED;
end;

destructor TMpuDialog.Destroy;
begin
  if FhDlgIcon <> 0 then
    DestroyIcon(FhDlgIcon);
  if FhBannerFont <> 0 then
    DeleteObject(FhBannerFont);
  inherited;
end;

////////////////////////////////////////////////////////////////////////////////
// Procedure : TMpuDialog.Run
// Comment   :

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
// Procedure : TMpuDialog.MakeProcInstance
// Comment   : Push the self parameter onto the stack

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

procedure TMpuDialog.SetDlgCaption(Caption: WideString);
begin
  SetWindowTextW(Self.Handle, PWideChar(Caption));
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

function TMpuDialog.GetAppTitle: WideString;
begin
  Result := FAppTitle;
end;

procedure TMpuDialog.SetAppTitle(Value: WideString);
begin
  FAppTitle := Value;
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
begin
  SetDlgCaption(AppTitle);
  SetBannerCaption;
  SetDlgIcon;

  FOldAppTitle := Self.GetAppTitle;

  FLogFont := GetSystemFont;
  FLogFont.lfHeight := BANNERFONTSIZE;
  FLOgFont.lfWeight := 900;
  FhBannerFont := CreateFontIndirect(FLogFont);
  if FhBannerFont <> 0 then
  begin
    SendDlgItemMessage(hDlg, IDC_STC_BANNER, WM_SETFONT, Integer(FhBannerFont), Integer(true));
  end;

  SetFocus(GetDlgItem(Handle, IDC_EDT_INPUT));

  SendDlgItemMessage(Handle, IDC_PB, PBM_SETRANGE32, 0, 100);
  SendDlgItemMessage(Handle, IDC_UD_OWCOUNT, UDM_SETRANGE32, 1, 50);
  SetDlgItemInt(Handle, IDC_EDT_OWCOUNT, 35, False);

  EnableControl(Handle, IDC_BTN_ENC, False);
  EnableControl(Handle, IDC_BTN_DEC, False);
  EnableControl(Handle, IDC_BTN_CANCEL, False);
  EnableControl(Handle, IDC_EDT_OWCOUNT, False);
  EnableControl(Handle, IDC_UD_OWCOUNT, False);
  EnableControl(Handle, IDC_STC_OWCOUNT, False);

  Result := True;
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
  MoveWindow(GetDlgItem(Self.Handle, IDC_STC_DEVIDER), 0, 74, loword(lParam), 2, True);
  // Client area controls
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

function TMpuDialog.OnCommand: Boolean;
var
  SrcFilename       : string;
  DestFilename      : string;
  Pwd               : string;
  Pwd2              : string;
  PwdQulty          : Extended;
begin
  Result := True;
  // accel for closing the dialog with ESC
  if FwParam = ID_CANCEL then
    OnClose;
  // Button clicks
  if hiword(FwParam) = BN_CLICKED then
  begin
    case LoWord(FwParam) of
      IDC_BTN_ABOUT: TAboutWnd.MsgBox(Self.Handle, 1, ABOUTEX);
      IDC_BTN_OPEN_IN:
        begin
          SrcFilename := OpenFile(Handle, '*.*');
          SetDlgItemText(Handle, IDC_EDT_INPUT, PChar(SrcFilename));
          SetDlgItemText(Handle, IDC_EDT_OUTPUT, PChar(SrcFilename));
        end;
      IDC_BTN_OPEN_OUT:
        begin
          DestFilename := SaveFileAs(Handle, '*.*', '');
          SetDlgItemText(Handle, IDC_EDT_OUTPUT, PChar(DestFilename));
        end;
      IDC_CHK_DELSOURCE:
        begin
          EnableControl(Handle, IDC_EDT_OWCOUNT, GetDlgBtnCheck(Handle, IDC_CHK_DELSOURCE));
          EnableControl(Handle, IDC_UD_OWCOUNT, GetDlgBtnCheck(Handle, IDC_CHK_DELSOURCE));
          EnableControl(Handle, IDC_STC_OWCOUNT, GetDlgBtnCheck(Handle, IDC_CHK_DELSOURCE));
        end;
      IDC_BTN_ENC:
        begin
          SrcFilename := GetItemText(Handle, IDC_EDT_INPUT);
          DestFilename := GetItemText(Handle, IDC_EDT_OUTPUT);
          Pwd := GetItemText(Handle, IDC_EDT_PWD1);
          EnableControl(Handle, IDC_BTN_ENC, False);
          EnableControl(Handle, IDC_BTN_DEC, False);
          EnableControl(Handle, IDC_BTN_CANCEL, True);
          SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 0, lParam(PChar(rsEncrypt)));
          Encrypt(SrcFilename, DestFilename, Pwd);
          SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 0, lParam(PChar(nil)));
          SendDlgItemMessage(Self.Handle, IDC_PB, PBM_SETPOS, 0, 0);
          EnableControl(Handle, IDC_BTN_ENC, True);
          EnableControl(Handle, IDC_BTN_DEC, True);
          EnableControl(Handle, IDC_BTN_CANCEL, False);
        end;
      IDC_BTN_DEC:
        begin
          SrcFilename := GetItemText(Handle, IDC_EDT_INPUT);
          DestFilename := GetItemText(Handle, IDC_EDT_OUTPUT);
          Pwd := GetItemText(Handle, IDC_EDT_PWD1);
          EnableControl(Handle, IDC_BTN_ENC, False);
          EnableControl(Handle, IDC_BTN_DEC, False);
          EnableControl(Handle, IDC_BTN_CANCEL, True);
          SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 0, lParam(PChar(rsDecrypt)));
          Decrypt(SrcFilename, DestFilename, Pwd);
          SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 0, lParam(PChar(nil)));
          SendDlgItemMessage(Self.Handle, IDC_PB, PBM_SETPOS, 0, 0);
          EnableControl(Handle, IDC_BTN_ENC, True);
          EnableControl(Handle, IDC_BTN_DEC, True);
          EnableControl(Handle, IDC_BTN_CANCEL, False);
        end;
      IDC_BTN_CANCEL:
        begin
          FAbort := True;
          SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 0, lParam(PChar(nil)));
          SendDlgItemMessage(Self.Handle, IDC_PB, PBM_SETPOS, 0, 0);
          EnableControl(Handle, IDC_BTN_ENC, True);
          EnableControl(Handle, IDC_BTN_DEC, True);
          EnableControl(Handle, IDC_BTN_CANCEL, False);
        end;
    end
  end;
  if hiword(FwParam) = EN_CHANGE then
  begin
    Pwd := '';
    Pwd2 := '';
    SrcFilename := GetItemText(Handle, IDC_EDT_INPUT);
    DestFilename := GetItemText(Handle, IDC_EDT_OUTPUT);
    Pwd := GetItemText(Handle, IDC_EDT_PWD1);
    Pwd2 := GetItemText(Handle, IDC_EDT_PWD2);
    AddToolTip(Handle, IDC_EDT_INPUT, @ti, PChar(SrcFilename));
    AddToolTip(Handle, IDC_EDT_OUTPUT, @ti, PChar(DestFilename));
    PwdQulty := TEncrypt.PwdQuality(Pwd);
    SetDlgItemText(Handle, IDC_STC_PWDQULTY, PChar(FloatToStr(PwdQulty, 0, 2)));
    if (SrcFilename <> '') and (FileExists(SrcFilename)) and (DestFilename <> '') and (Pwd <> '') and (Pwd2 <> '') and
      (Pwd
      = Pwd2) then
    begin
      EnableControl(Handle, IDC_BTN_ENC, True);
    end
    else
    begin
      EnableControl(Handle, IDC_BTN_ENC, False);
    end;

    if (SrcFilename <> '') and (DestFilename <> '') and (Pwd <> '') then
    begin
      EnableControl(Handle, IDC_BTN_DEC, True);
      EnableControl(handle, IDC_CHK_DELSOURCE, True);
    end
    else
    begin
      EnableControl(Handle, IDC_BTN_DEC, False);
      EnableControl(handle, IDC_CHK_DELSOURCE, False);
    end;
  end;
  // accelerators
  if hiword(FwParam) = 1 then
  begin
    case loword(FwParam) of
      ID_ACCEL_CLOSE: OnClose;
    end;
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
    WM_DROPFILES:
      begin
        OnDropFiles(wParam, lParam);
      end;
  else
    Result := False;
  end;
end;

procedure TMpuDialog.OnDropFiles(wParam: WPARAM; lParam: LPARAM);
var
  hDrop             : THandle;
  Filename          : array[0..MAX_PATH] of Char;
begin
  hDrop := wParam;
  if DragQueryFile(hDrop, 0, Filename, MAX_PATH) > 0 then
  begin
    SetDlgItemText(Handle, IDC_EDT_INPUT, Filename);
  end;
end;

procedure TMpuDialog.OnProgress(Sender: TObject; PercentDone: Integer);
begin
  ProcessMessages(Handle);

  if FAbort then
    Abort;

  if FPercentDoneOld < PercentDone then
  begin
    SendDlgItemMessage(Handle, IDC_PB, PBM_SETPOS, PercentDone, 0);
    Self.SetDlgCaption(FormatW('%d%% - %s', [PercentDone, WideString(FOldAppTitle)]));
  end;
  FPercentDoneOld := PercentDone;
end;

procedure TMpuDialog.OnShredderStart(Sender: TObject);
begin
  SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 0, Integer(PChar(rsDelFile)));
  SendDlgItemMessage(Handle, IDC_PB, PBM_SETPOS, 0, 0);
end;

procedure TMpuDialog.OnShredderProgress(Sender: TObject; PercentDone: Cardinal);
begin
  if FAbort then
    Abort;
  SendDlgItemMessage(Handle, IDC_PB, PBM_SETPOS, PercentDone, 0);
  Self.SetDlgCaption(FormatW('%d%% - %s', [PercentDone, WideString(FOldAppTitle)]));
  ProcessMessages(Handle);
end;

procedure TMpuDialog.OnShredderFinish(Sender: TObject);
begin
  SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 0, Integer(PChar(nil)));
  SendDlgItemMessage(Self.Handle, IDC_PB, PBM_SETPOS, 0, 0);
  Self.SetDlgCaption(WideString(FOldAppTitle));
end;

procedure TMpuDialog.OnShredderPass(Sender: TObject; Pass, PassCount: Cardinal);
var
  s: String;
begin
  s := Format(rsDelFile, [Pass, PassCount]);
  SendDlgItemMessage(Self.Handle, IDC_SB, SB_SETTEXT, 0, Integer(PChar(s)));
end;

procedure TMpuDialog.Encrypt(const InFilename, OutFilename: string; const Pwd: string);
var
  Enc               : TEncrypt;
  Translated        : LongBool;
begin
  SendDlgItemMessage(Handle, IDC_PB, PBM_SETPOS, 0, 0);
  FAbort := False;
  Enc := TEncrypt.Create;
  try
    try
      Enc.Parent := Handle;
      Enc.SrcFilename := InFilename;
      Enc.DestFilename := OutFilename;
      Enc.Pwd := Pwd;
      Enc.DelSourceFile := GetDlgBtnCheck(Handle, IDC_CHK_DELSOURCE);
      Enc.PassCount := GetDlgItemInt(Handle, IDC_EDT_OWCOUNT, Translated, False);
      Enc.OnProgress := OnProgress;
      Enc.OnShredderStart := OnShredderStart;
      Enc.OnShredderProgress := OnShredderProgress;
      Enc.OnShredderFinish := OnShredderFinish;
      Enc.OnShredderPass := OnShredderPass;
      Enc.Encrypt;
    except
      on E: EAbort do
        MessageBoxW(Handle, PWideChar(WideString(rsAbort)), PWideChar(AppTitle), MB_ICONINFORMATION);
      on E: Exception do
        MessageBoxW(Handle, PWideChar(E.Message), PWideChar(AppTitle), MB_ICONERROR)
    end;
  finally
    Enc.Free;
  end;
end;

procedure TMpuDialog.Decrypt(const InFilename, OutFilename: string; const Pwd: string);
var
  Enc               : TEncrypt;
  Translated        : LongBool;
begin
  SendDlgItemMessage(Handle, IDC_PB, PBM_SETPOS, 0, 0);
  FAbort := False;
  Enc := TEncrypt.Create;
  try
    try
      Enc.Parent := Handle;
      Enc.SrcFilename := InFilename;
      Enc.DestFilename := OutFilename;
      Enc.Pwd := Pwd;
      Enc.DelSourceFile := GetDlgBtnCheck(Handle, IDC_CHK_DELSOURCE);
      Enc.PassCount := GetDlgItemInt(Handle, IDC_EDT_OWCOUNT, Translated, False);
      Enc.OnProgress := OnProgress;
      Enc.OnShredderStart := OnShredderStart;
      Enc.OnShredderProgress := OnShredderProgress;
      Enc.OnShredderFinish := OnShredderFinish;
      Enc.OnShredderPass := OnShredderPass;
      Enc.Decrypt;
    except
      on E: EAbort do
        MessageBoxW(Handle, PWideChar(WideString(rsAbort)), PWideChar(AppTitle), MB_ICONINFORMATION);
      on E: Exception do
        MessageBoxW(Handle, PWideChar(E.Message), PWideChar(AppTitle), MB_ICONERROR);
    end;
  finally
    Enc.Free;
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

