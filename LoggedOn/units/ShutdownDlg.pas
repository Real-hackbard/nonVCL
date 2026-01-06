{$INCLUDE CompilerSwitches.inc}

unit ShutdownDlg;

interface

uses
  Windows,
  Messages,
  MpuTools,
  constants;

function ShutdownDlgFunc(hDlg: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;

implementation

var
  Machine           : string;
  Login             : string;
  PW                : string;

function GetCheck(hDlg: THandle; ID: DWORD): Boolean;
begin
  Result := IsDlgButtonChecked(hDlg, ID) = BST_CHECKED;
end;

function NetErrorMessage(Error: DWORD): String; 
var 
  buffer: array [0..1024] of Char; 
  err: DWORD; 
begin 
  err := Error; 
  WNetGetLastError(err, buffer, sizeof(buffer), nil, 0); 
  result := String(buffer); 
end;

function ConnectToNetworkDrive(LocalName: string;
  RemoteName: string; Username: string; Password: string;
  RestoreAtLogon: boolean ): DWORD;
var
  NetResource: TNetResource;
  dwFlags:     DWORD;
begin
  dwFlags := 0;
  ZeroMemory(@NetResource, sizeof(TNetResource));
  with NetResource do begin
    dwType := RESOURCETYPE_DISK;
    lpLocalName := PChar(LocalName);
    lpRemoteName := PChar(RemoteName);
    lpProvider := nil;
  end;

  if (RestoreAtLogon) then
    dwFlags := dwFlags or CONNECT_UPDATE_PROFILE;

  Result := WNetAddConnection2(NetResource,PChar(Password), PChar(Username),dwFlags);
end;

function DisconnectNetworkDrive(Name: String): DWORD;
begin
  result := WNetCancelConnection2(PChar(Name), CONNECT_UPDATE_PROFILE, True);
end;

function EnablePrivilege(const Privilege: string; fEnable: Boolean; out PreviousState: Boolean): DWORD;
var
  Token: THandle;
  NewState: TTokenPrivileges;
  Luid: TLargeInteger;
  PrevState: TTokenPrivileges;
  Return: DWORD;
begin
  if (GetVersion() > $80000000) then
    // Win9x
    Result := ERROR_SUCCESS
  else
  begin
    // WinNT
    if not OpenProcessToken(GetCurrentProcess(), MAXIMUM_ALLOWED, Token) then
      Result := GetLastError()
    else
    try
      if not LookupPrivilegeValue(nil, PChar(Privilege), Luid) then
        Result := GetLastError()
      else
      begin
        NewState.PrivilegeCount := 1;
        NewState.Privileges[0].Luid := Luid;
        if fEnable then
          NewState.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED
        else
          NewState.Privileges[0].Attributes := 0;
        if not AdjustTokenPrivileges(Token, False, NewState,
          SizeOf(TTokenPrivileges), PrevState, Return) then
          Result := GetLastError()
        else
        begin
          Result := ERROR_SUCCESS;
          PreviousState := (PrevState.Privileges[0].Attributes and SE_PRIVILEGE_ENABLED <> 0);
        end;
      end;
    finally
      CloseHandle(Token);
    end;
  end;
end;

function InitShutDown(Computer: string; Text: string; Timeout: DWORD; Force: Boolean; Reboot: Boolean): Integer;
var
  PrevState: Boolean;
  RetValue: DWORD;
begin
  Result := 0;
  RetValue := EnablePrivilege('SeRemoteShutdownPrivilege', True, PrevState);
  if RetValue = ERROR_SUCCESS then
  begin
    if not InitiateSystemShutdown(PChar(Computer), PChar(Text), Timeout, Force, Reboot) then
      Result := GetLastError;
  end;
  EnablePrivilege('SeRemoteShutdownPrivilege', PrevState, PrevState);
end;

function ShutdownDlgFunc(hDlg: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;
var
  Buffer: array[0..255] of Char;
  res: Integer;
  Text: String;
  TimeOut: Integer;
  Translated: BOOL;
begin
  Result := True;
  case uMsg of
    WM_INITDIALOG:
      begin
        Machine := PShutdownParams(lParam)^.Machine;
        SetDlgItemText(hDlg, IDC_STC_MACHINE, PChar(Machine));
        CheckDlgButton(hDlg, IDC_RBN_SHUTDOWN, BST_CHECKED);
        SetDlgItemInt(hDlg, IDC_EDT_TIMEOUT, 10, False);
        EnableControl(hDlg, IDC_BTN_OK, False);
      end;
    WM_CLOSE:
      begin
        DisconnectNetworkDrive('\\' + Machine + '\IPC$');
        EndDialog(hDlg, 0);
      end;
    WM_COMMAND:
      begin
        if wParam = ID_CANCEL then
          SendMessage(hDlg, WM_CLOSE, 0, 0);
        if hiword(wParam) = EN_CHANGE then
        begin
          case loword(wparam) of
            IDC_EDT_LOGIN:
              begin
                GetDlgItemText(hDlg, IDC_EDT_LOGIN, @Buffer[0], 255);
                Login := string(Buffer);
                EnableControl(hDlg, IDC_BTN_OK, (Login <> ''));
              end;
          end;
        end;
        if hiword(wParam) = BN_CLICKED then
        begin
          case LoWord(wParam) of
            IDC_BTN_OK:
            begin
              // Just in case we are already connected...
              DisconnectNetworkDrive('\\' + Machine + '\IPC$');
              res := ConnectToNetworkDrive('', '\\' + Machine + '\IPC$', Login, PW, False);
              if res = NO_ERROR then
              begin
                GetDlgItemText(hDlg, IDC_EDT_MSG, @Buffer[0], sizeof(Buffer));
                Text := string(Buffer);
                TimeOut := GetDlgItemInt(hDlg, IDC_EDT_TIMEOUT, Translated, False);
                res := InitShutDown('\\' + Machine, Text, Timeout, GetCheck(hDlg, IDC_CHK_FORCE), GetCheck(hDlg, IDC_RBN_REBOOT));
                if res <> 0 then
                  MessageBoxW(hDlg, PWideChar(SysErrorMessage(res)), PWideChar(WideString(rsShutdown)), MB_ICONERROR);
                DisconnectNetworkDrive('\\' + Machine + '\IPC$');
              end
              else if res = ERROR_EXTENDED_ERROR then
              begin
                MessageBox(hDlg, PChar(NetErrorMessage(res)), PChar(rsShutdown), MB_ICONERROR);
              end
              else
                MessageBoxW(hDlg, PWideChar(SysErrorMessage(res)), PWideChar(WideString(rsShutdown)), MB_ICONERROR);
            end;
            IDC_BTN_CANCEL1: SendMessage(hDlg, WM_CLOSE, 0, 0);
          end;
        end;
      end;
  else
    Result := False;
  end;
end;

end.

