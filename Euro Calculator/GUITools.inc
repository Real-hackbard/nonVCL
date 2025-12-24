{******************************************************************************}
{                      GUITools - Version 1.1 (2002-10-21)                     }
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

{*******************************************************************************
                               -=LICENSE=-

THIS PROGRAM / SOURCE-FILE IS FREEWARE WITH SOURCE.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

The source is provided under the conditions of the GNU General Public License.
See gpl-license.txt for details or visit www.gnu.org.

You may alter it as you want, but leave a note on what is your source.
The only condition is to not misrepresent its origin (Keep the file header as it
is, don't remove the copyright information). Therefore, only do not claim this
source to be your mind work - you need not to credit me or something, even if it
would be nice. If you distribute this program and/or source, I would like to get
a free copy (this is voluntary :o) ).

*******************************************************************************}

const
  TTS_BALLOON    = $40;

var
  hTooltip: Cardinal;
  ti: TToolInfo;

{******************************************************************************}
(*   Nobody, Eugen Honecker (?)                                               *)
{******************************************************************************}
procedure ShowHelpText(wParam: WPARAM; lParam: LPARAM; hSB: HWND);
(****************************************************************
 procedure ShowHelpText
 Rückgabewert: %

 Funktion:
 Weist einem Menüeintrag den zugehörigen Hilfetext für die Statusbar zu

 Aufruf:
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

{******************************************************************************}
(*   Nico Bendlin, Michael Puff                                               *)
{******************************************************************************}
procedure CreateToolTips(hWnd: Cardinal);
(****************************************************************
 procedure CreateTooltips
 Rückgabewert: %

 Funktion:
 Erzeugt ein Tooltipfenster für ein Fenster
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

{******************************************************************************}
(*   Nico Bendlin, Michael Puff                                               *)
{******************************************************************************}
procedure AddToolTip(hwnd, id: DWORD; lpti: PToolInfo; lpText: PChar);
(****************************************************************
 procedure AddTooltip
 Rückgabewert: %

 Funktion:
 Weist einem Kontroll ein Tooltipfenster zu
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

{******************************************************************************}
(*   Eugen Honeker                                                            *)
{******************************************************************************}
function Format(fmt: string; params: array of const): string;
(****************************************************************
 function Format
 Rückgabewert: String (Formatierter String entsprechend der Formatbeschreiber)

 Funktion:
 Formatiert einen String entsprechend der Formatbeschreiber und Argumente.
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