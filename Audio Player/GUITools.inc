const
  TTS_BALLOON    = $40;

var
  hTooltip: Cardinal;
  ti: TToolInfo;

procedure ShowHelpText(wParam: WPARAM; lParam: LPARAM; hSB: HWND);
var
  bla: array of integer;
begin
  if BOOL(HIWORD(wParam) and MF_POPUP) or
     BOOL(HIWORD(wParam) and MF_SEPARATOR) or
     (HIWORD(wParam) = $FFFF)                         // leave menu
  then
    SendMessage(hSB, SB_SIMPLE, 0, 0)
  else
    MenuHelp(WM_MENUSELECT, wParam, lParam, HMENU(lParam), hInstance, hSB, @bla);
end;

procedure CreateToolTips(hWnd: Cardinal);
begin
  hToolTip := CreateWindowEx(0, 'Tooltips_Class32', nil, TTS_ALWAYSTIP,
    Integer(CW_USEDEFAULT), Integer(CW_USEDEFAULT),Integer(CW_USEDEFAULT),
    Integer(CW_USEDEFAULT), hWnd, 0, hInstance, nil);
  if hToolTip <> 0 then
  begin
    SetWindowPos(hToolTip, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or
      SWP_NOSIZE or SWP_NOACTIVATE);
    ti.cbSize := SizeOf(TToolInfo);
    ti.uFlags := TTF_SUBCLASS;
    ti.hInst := hInstance;
  end;
end;

procedure AddToolTip(hwnd, id: Cardinal; lpti: PToolInfo; lpText: PChar);
var
  Item: THandle;
  Rect: TRect;
begin
  Item := GetDlgItem(hWnd, id);
  if (Item <> 0) AND (GetClientRect(Item, Rect)) then
  begin
    lpti.hwnd := Item;
    lpti.Rect := Rect;
    lpti.lpszText := lpText;
    SendMessage(hToolTip, TTM_ADDTOOL, 0, Integer(lpti));
  end;
end;
