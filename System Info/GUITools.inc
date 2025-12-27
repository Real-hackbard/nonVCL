{******************************************************************************}
{                      GUITools - Version 1.2 (2003-02-08)                     }
{                                                                              }
{                   Compilation 2002 Michael .:Luckie:. Puff                   }
{                                                                              }
{                           www.luckie-online.de                               }
{                          mpuff@luckie-online.de                              }
{                                                                              }
{                                                                              }
{                     The Nightflyer keeps coding...                           }
{                                                                              }
{ Contributors: Assarbad                                                       }
{               Nico Bendlin                                                   }
{               Eugen Honeker                                                  }
{               Michael .:Luckie:. Puff                                        }
{               Mathias Simmack                                                }
{******************************************************************************}

const
  TTS_BALLOON    = $40;

var
  hTooltip: Cardinal;
  ti: TToolInfo;

{-----------------------------------------------------------------------------
  Procedure : ShowHelpText
  Author    :    
  Date      : 2003-02-08
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
    MenuHelp(WM_MENUSELECT, wParam, lParam, HMENU(lParam), hInstance, hSB, @bla);
end;

{-----------------------------------------------------------------------------
  Procedure : CreateToolTips
  Author    : Nico bendlin, Michael Puff
  Date      : 2003-02-08
  Purpose   : Creates a Tooltip-Window
  Arguments : hWnd: Cardinal
  Result    : None
-----------------------------------------------------------------------------}
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

{-----------------------------------------------------------------------------
  Procedure : AddToolTip
  Author    : Nico Bendlin, Michael Puff
  Date      : 2003-02-08
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