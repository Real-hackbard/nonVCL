const
  TTS_BALLOON    = $40;

var
  hTooltip: Cardinal;
  ti: TToolInfo;

{-----------------------------------------------------------------------------
  Procedure : ShowHelpText
  Author    :    
  Purpose   : Displays helptext of a menu item in the satausbar
  Arguments : wParam: WPARAM; lParam: LPARAM; hSB: HWND
  Result    : None

  Aufruf:
  WM_MENUSELECT:
  begin
    ShowHelpText(wParam, lParam, hStatbar);
    Result:= false;
  end;
-----------------------------------------------------------------------------}
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
    MenuHelp(WM_MENUSELECT, wParam, lParam, HMENU(lParam), hInstance, hSB,
      PUINT(@bla));
end;

{-----------------------------------------------------------------------------
  Procedure : CreateToolTips
  Purpose   : Creates a Tooltip-Window
  Arguments : hWnd: Cardinal
  Result    : None
-----------------------------------------------------------------------------}
procedure CreateToolTips(hWnd: Cardinal);
begin
  hToolTip := CreateWindowEx(0, 'Tooltips_Class32', nil, TTS_ALWAYSTIP or TTS_BALLOON,
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

{-----------------------------------------------------------------------------
  Procedure : AddToolTip
  Purpose   : Adds a tooltip to a window
  Arguments : hwnd, id: Cardinal; lpti: PToolInfo; lpText: PChar
  Result    : None
-----------------------------------------------------------------------------}
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

{-----------------------------------------------------------------------------
  Procedure : Format
  Purpose   : Formats a string according to the formatdiscriptors
  Arguments : fmt: string; params: array of const
  Result    : string
-----------------------------------------------------------------------------}
function Format(fmt: string; params: array of const): string;
var
  pdw1, pdw2: PDWORD;
  i: integer;
  pc: PCHAR;
begin
  pdw1 := nil;
  if length(params) > 0 then GetMem(pdw1, length(params) * sizeof(Pointer));
  pdw2 := pdw1;
  for i := 0 to high(params) do begin
    pdw2^ := DWORD(PDWORD(@params[i])^);
    inc(pdw2);
  end;
  GetMem(pc, 1024 - 1);
  try
    SetString(Result, pc, wvsprintf(pc, PCHAR(fmt), PCHAR(pdw1)));
  except
    Result := '';
  end;
  if (pdw1 <> nil) then FreeMem(pdw1);
  if (pc <> nil) then FreeMem(pc);
end;