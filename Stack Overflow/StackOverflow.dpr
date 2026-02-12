{$I compilerswitches.inc}

program StackOverflow;

uses
  windows,
  messages,
  CommCtrl,
  SysUtils; // Exceptions

const
  IDC_EDT_VALUE     = 101;
  IDC_BTN_START     = 102;
  IDC_STC_RESULT    = 103;

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
    procedure OnClose(ExitCode: Integer = 0);
  public
    property Handle: THandle read GethApp;
    property AppTitle: WideString read GetAppTitle write SetAppTitle;
    property Icon: THandle read GetIcon write SetIcon;
  end;


function Sum(Num: Integer): Integer;
begin
  if Num = 0 then
    result := 0
  else
    result := Num + Sum(Num - 1);
end;

function SumThread(p: Pointer): Integer;
var
  Max               : Integer;
  Summe             : Integer;
begin
  // Parameter p contains the number of numbers to be added.
  Max := Integer(p);
  try
    // To catch an exception caused by a stack overflow,
    // The Sum function must be called within a try-except block.
    Summe := Sum(Max);
  except
    on E: EStackOverflow do
      // The Sum function must be called within a try-except block.
      Summe := MaxInt;
  end;
  Result := Summe;
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
  Buffer: array[0..255] of Char;//

  Translated        : LongBool;
  MaxValue          : Integer;
  ThreadID          : Cardinal;
  hThread           : THandle;
  Summe             : Cardinal;
begin
  Result := True;
  // accel for closing the dialog with ESC
  if FwParam = ID_CANCEL then
    OnClose;
  // Button clicks
  if hiword(FwParam) = BN_CLICKED then
  begin
    case loword(FwParam) of
      IDC_BTN_START:
        begin
          MaxValue := GetDlgItemInt(Handle, IDC_EDT_VALUE, Translated, False);
          hThread := BeginThread(nil, 0, @SumThread, Pointer(MaxValue), 0, ThreadID);
          // Wait for thread.
          WaitForSingleObject(hThread, INFINITE);
          // ExitCode contains the sum.
          GetExitCodeThread(hThread, Summe);
          // Close thread handle
          CloseHandle(hThread);
          // If the return value equals MaxInt, then a stack overflow has occurred.
          if Summe = MaxInt then
            SetDlgItemText(Handle, IDC_STC_RESULT, PChar('Überlauf'))
          else
            SetDlgItemInt(Handle, IDC_STC_RESULT, Summe, False);
        end;
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
  Result := True;
  case uMsg of
    WM_INITDIALOG:
      begin
        Result := OnInitDialog(Handle, uMsg, wParam, lParam);
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
  MpuDialog         : TMpuDialog;

begin
  MpuDialog := TMpuDialog.Create;
  try
    MpuDialog.AppTitle := 'StackOverflow';
    ExitCode := MpuDialog.Run;
  finally
    MpuDialog.Free;
  end;
end.

