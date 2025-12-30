const
  TTS_BALLOON    = $40;

var
  hTooltip: Cardinal;
  ti: TToolInfo;

procedure ShowHelpText(wParam: WPARAM; lParam: LPARAM; hSB: HWND);
(****************************************************************
 procedure ShowHelpText
 Return value: %

 Function:
 Assigns the corresponding help text for the status bar to a menu item.

 Call:
 WM_MENUSELECT:
 begin
   ShowHelpText(wParam, lParam, hStatbar);
   Result:= false;
 end;
****************************************************************)
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
(****************************************************************
 procedure CreateTooltips
 Return value: %

 Function:
 Creates a tooltip window for a window
****************************************************************)
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

procedure AddToolTip(hwnd, id: DWORD; lpti: PToolInfo; lpText: PChar);
(****************************************************************
 procedure AddTooltip
 Return value: %

 Function:
 Assigns a tooltip window to a control
****************************************************************)
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

function Format(fmt: string; params: array of const): string;
(****************************************************************
 function Format
 Return value: String (Formatted string according to the format description)

 Function:
 Formats a string according to the format descriptor and arguments..
****************************************************************)
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