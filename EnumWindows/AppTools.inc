////////////////////////////////////////////////////////////////////////////////
// Procedure : RaiseLastError
// Comment   : Displays messagebox with last error

procedure RaiseLastError(hWnd: cardinal);
var
  LastError: DWORD;
  szBuffer, szError, szCaption : array[0..255] of Char;
begin
  LastError := GetLastError;
  wvsprintf(szBuffer, 'Win32-Fehler. Code: %d', PChar(@LastError));
  lstrcat(szBuffer, #13#10);
  FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, nil, GetLastError, 0, szError,
    sizeof(szError), nil);
  lstrcat(szBuffer, szError);

  GetWindowText(hWnd, szCaption, sizeof(szCaption));
  MessageBox(hWnd, szBuffer, szCaption, MB_ICONSTOP or MB_APPLMODAL);
end;

////////////////////////////////////////////////////////////////////////////////
// Procedure : SysErrorMessage
// Comment   : Returns last error as formated string

function SysErrorMessage(ErrorCode: Integer): string;
var
  Len: Integer;
  Buffer: array[0..255] of Char;
begin
  Len := FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM or
    FORMAT_MESSAGE_ARGUMENT_ARRAY, nil, ErrorCode, 0, Buffer,
    SizeOf(Buffer), nil);
  while (Len > 0) and (Buffer[Len - 1] in [#0..#32, '.']) do Dec(Len);
  SetString(Result, Buffer, Len);
end;

////////////////////////////////////////////////////////////////////////////////
// Procedure : MyMessageBox
// Comment   : Wrapper for MsgBoxParams

procedure MyMessageBox(hWnd: HWND; caption, Text: String; IDIcon: DWORD);
var
  MsgInfo: TMsgBoxParams;
begin
  MsgInfo.cbSize := SizeOf(TMsgBoxParams);
  MsgInfo.hwndOwner := hWnd;
  MsgInfo.hInstance := GetWindowLong(hWnd, GWL_HINSTANCE);
  MsgInfo.lpszText :=  @Text[1];
  MsgInfo.lpszCaption := @Caption[1];
  MsgInfo.dwStyle := MB_USERICON;
  MsgInfo.lpszIcon := MAKEINTRESOURCE(IDICON);
  MessageBoxIndirect(MsgInfo);
end;

////////////////////////////////////////////////////////////////////////////////
// Procedure : LoadStr
// Comment   : Loads a resource string

function LoadStr(ID: DWORD): String;
var
  buffer: array[0..255] of Char;
begin
  LoadString(hInstance, ID, buffer, 255);
  result := String(buffer);
end;

////////////////////////////////////////////////////////////////////////////////
// Procedure : ProcessMessages
// Comment   : Replacement for ProcessMesaages of TApplication

procedure ProcessMessages(hWnd: DWORD);
var
  Msg: TMsg;
begin
  while PeekMessage(Msg, hWnd, 0, 0, PM_REMOVE) do
    begin
      TranslateMessage(Msg);
      DispatchMessage(Msg);
    end;
end;

