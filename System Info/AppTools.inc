{-----------------------------------------------------------------------------
  Procedure : RaiseLastError
  Purpose   : Displays formatted error message
  Arguments : hWnd: cardinal
  Result    : None
-----------------------------------------------------------------------------}
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

{-----------------------------------------------------------------------------
  Procedure : MyMessagebox
  Purpose   : Displays own About-Box
  Arguments : hWnd: HWND; Text: String; IDIcon: DWORD
  Result    : None
-----------------------------------------------------------------------------}
procedure MyMessagebox(hWnd: HWND; caption, Text: String; IDIcon: DWORD);
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

{-----------------------------------------------------------------------------
  Procedure : LoadStr
  Purpose   : Loads a string from a resource
  Arguments : ID: DWORD
  Result    : String
-----------------------------------------------------------------------------}
function LoadStr(ID: DWORD): String;
var
  buffer: array[0..255] of Char;
begin
  LoadString(hInstance, ID, buffer, 255);
  result := String(buffer);
end;

{-----------------------------------------------------------------------------
  Procedure : ProcessMessages
  Purpose   : Replacement for Application.ProcessMessages
  Arguments : hWnd: DWORD
  Result    : None
-----------------------------------------------------------------------------}
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