const
  TTS_BALLOON       = $40;

var
  hTooltip          : Cardinal;
  ti                : TToolInfo;

function Point(X, Y: Integer): TPoint;
begin
  Result.X := X;
  Result.Y := Y;
end;

function GetSystemFont: TLogFont;
begin
  GetObject(GetStockObject(DEFAULT_GUI_FONT), sizeof(Result), @Result);
end;

function CreateToolTips(hWnd: Cardinal; bBalloon: Boolean = False): Boolean;
const
  TTF_PARSELINKS    = $1000;
var
  Styles            : DWORD;
begin
  Styles := TTS_ALWAYSTIP;
  if bBalloon then
    Styles := Styles or TTS_BALLOON;
  result := False;
  hToolTip := CreateWindowEx(0, 'Tooltips_Class32', nil, Styles,
    Integer(CW_USEDEFAULT), Integer(CW_USEDEFAULT), Integer(CW_USEDEFAULT),
    Integer(CW_USEDEFAULT), hWnd, 0, hInstance, nil);
  if hToolTip <> 0 then
  begin
    SetWindowPos(hToolTip, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or
      SWP_NOSIZE or SWP_NOACTIVATE);
    ti.cbSize := SizeOf(TToolInfo);
    ti.uFlags := TTF_SUBCLASS or TTF_PARSELINKS;
    ti.hInst := hInstance;
    result := True;
  end;
end;

procedure AddToolTip(hwnd, id: Cardinal; ti: PToolInfo; Text: String; Caption: String = ''; IDIcon: DWORD = 0);
const
  TTM_SETTITLE      = WM_USER + 32;
var
  Item              : THandle;
  Rect              : TRect;
begin
  Item := GetDlgItem(hWnd, id);
  if (Item <> 0) and (GetClientRect(Item, Rect)) then
  begin
    //ZeroMemory(@ti, sizeof(TToolInfo));
    ti.hwnd := Item;
    ti.Rect := Rect;
    ti.lpszText := PChar(Text);
    SendMessage(hToolTip, TTM_ADDTOOL, 0, Integer(ti));
    SendMessage(hToolTip, TTM_SETTITLE, IDIcon, Integer(@Caption[1]));
  end;
end;