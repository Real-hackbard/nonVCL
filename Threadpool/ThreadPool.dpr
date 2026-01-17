{$I compilerswitches.inc}

program ThreadPool;

uses
  windows,
  messages,
  CommCtrl,
  TlHelp32; // CountThreads

const
  IDC_BTN_START     = 101;
  IDC_CHK_LONGFUNCTION = 103;
  IDC_EDT_REQUESTS  = 106;
  IDC_STC_THREADS   = 105;

  ID_ACCEL_CLOSE    = 4001;

{$R .\res\resource.res}

type
  TMpuDialog = class(TObject)
  private
    FHandle: THandle;
    FDlgFuncPtr: Pointer;
    FMsg: UINT;
    FwParam: WPARAM;
    FlParam: LPARAM;
    FAppTitle: WideString;
    FhDlgIcon: THandle;
    FRequests: Integer;
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
    // Event handlers
    function OnInitDialog(hDlg: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): Boolean;
    function OnCommand: Boolean;
  public
    property Handle: THandle read GethApp;
    property AppTitle: WideString read GetAppTitle write SetAppTitle;
    property Icon: THandle read GetIcon write SetIcon;
  end;

function QueueUserWorkItem(LPTHREAD_START_ROUTINE: Pointer; Context: Pointer; Flags: DWORD): DWORD; stdcall; external
  'kernel32.dll';

const
  WT_EXECUTEDEFAULT = $00000000;
  WT_EXECUTEINIOTHREAD = $00000001;
  WT_EXECUTEINUITHREAD = $00000002;
  WT_EXECUTEINWAITTHREAD = $00000004;
  WT_EXECUTEONLYONCE = $00000008;
  WT_EXECUTEINTIMERTHREAD = $00000020;
  WT_EXECUTELONGFUNCTION = $00000010;
  WT_EXECUTEINPERSISTENTIOTHREAD = $00000040;
  WT_EXECUTEINPERSISTENTTHREAD = $00000080;
  WT_TRANSFER_IMPERSONATION = $00000100;

function CountThreads(ProcID: DWORD): Integer;
var
  hSnapShot         : THandle;
  pe32              : TProcessEntry32;
begin
  result := 0;

  hSnapShot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, ProcID);
  if hSnapShot <> INVALID_HANDLE_VALUE then
  begin
    ZeroMemory(@pe32, sizeof(TProcessEntry32));
    pe32.dwSize := sizeof(TProcessEntry32);
    Process32First(hSnapShot, pe32);
    if pe32.th32ProcessID = ProcID then
    begin
      result := pe32.cntThreads;
    end
    else
    begin
      repeat
        if pe32.th32ProcessID = ProcID then
        begin
          result := pe32.cntThreads;
          break;
        end;
      until Process32Next(hSnapShot, pe32) = False;
    end;
  end;
end;

function Thread(p: Pointer): Integer; stdcall;
var
  i                 : Integer;
begin
  for i := 0 to 1000 do
    Sleep(1);
  result := 0;
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

procedure TMpuDialog.SetDlgCaption;
begin
  SetWindowTextW(Self.Handle, PWideChar(AppTitle));
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
  SetDlgCaption;
  Result := True;
end;

function TMpuDialog.OnCommand: Boolean;
var
  i: Integer;
  Translated: BOOL;
  Flags: Integer;
begin
  Result := True;
  if FwParam = ID_CANCEL then
    PostQuitMessage(0);
  if hiword(FwParam) = BN_CLICKED then
  begin
    case loword(FwParam) of
      IDC_BTN_START:
        begin
          if IsDlgButtonChecked(Handle, IDC_CHK_LONGFUNCTION) = BST_CHECKED then
            Flags := WT_EXECUTEDEFAULT or WT_EXECUTELONGFUNCTION
          else
            Flags := WT_EXECUTEDEFAULT;
          for i := 0 to GetDlgItemInt(Handle, IDC_EDT_REQUESTS, Translated, False) do
            QueueUserWorkItem(@Thread, nil, Flags);
        end;
    end;
  end;
end;

function TMpuDialog.DlgFunc(hDlg: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;
begin
  Result := True;
  FHandle := hDlg;
  FMsg := uMsg;
  FwParam := wParam;
  FlParam := lparam;
  case uMsg of
    WM_INITDIALOG:
      begin
        FRequests := 0;
        SetTimer(Handle, 0, 10, nil);
        Result := OnInitDialog(Handle, uMsg, wParam, lParam);
      end;
    WM_TIMER:
      begin
        SetDlgItemInt(Handle, IDC_STC_THREADS, CountThreads(GetCurrentProcessId), False);
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
  MpuDialog         : TMpuDialog;

begin
  MpuDialog := TMpuDialog.Create;
  try
    MpuDialog.AppTitle := 'Queue User Work Item';
    ExitCode := MpuDialog.Run;
  finally
    MpuDialog.Free;
  end;
end.

