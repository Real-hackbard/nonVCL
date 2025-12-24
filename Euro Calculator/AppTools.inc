{******************************************************************************}
{                                                                              }
{                     AppTools - Version 1.1 (2002-10-21)                      }
{                                                                              }
{                 Copyright (c) 2002 Michael .:Luckie:. Puff                   }
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


{******************************************************************************}
(*   Michael Puff                                                             *)
{******************************************************************************}
procedure RaiseLastError(hWnd: cardinal);
(****************************************************************
 procedure RaiseLastError
 Rückgabewert: %

 Funktion:
 Gibt den letzten Windows-Fehler zurück
 (und manch mal auch den aller letzten :o) )
****************************************************************)
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

{******************************************************************************}
(*   Michael Puff                                                             *)
{******************************************************************************}
procedure MyMessagebox(hWnd: HWND; Text: String; IDIcon: DWORD);
(****************************************************************
 procedure MyMessagebox
 Rückgabewert: %

 Funktion:
 Zeigt eine Messagebox mit eigenem Icon an.
****************************************************************)
var
  MsgInfo: TMsgBoxParams;
begin
  MsgInfo.cbSize := SizeOf(TMsgBoxParams);
  MsgInfo.hwndOwner := hWnd;
  MsgInfo.hInstance := GetWindowLong(hWnd, GWL_HINSTANCE);
  MsgInfo.lpszText :=  @Text[1];
  MsgInfo.lpszCaption := 'Information...';
  MsgInfo.dwStyle := MB_USERICON;
  MsgInfo.lpszIcon := MAKEINTRESOURCE(IDICON);
  MessageBoxIndirect(MsgInfo);
end;

{******************************************************************************}
(*   Michael Puff                                                             *)
{******************************************************************************}
function LoadStr(ID: DWORD): String;
(****************************************************************
 function LoadStr
 Rückgabewert: String (aus der Ressource)

 Funktion:
 Läd den mit der ID angegbenen String aus der Ressource.
****************************************************************)
var
  buffer: array[0..255] of Char;
begin
  LoadString(hInstance, ID, buffer, 255);
  result := String(buffer);
end;

{******************************************************************************}
(*   Nico Bendlin                                                             *)
{******************************************************************************}
procedure ProcessMessages(hWnd: DWORD);
(****************************************************************
 procedure ProcessMessages
 Rückgabewert: %

 Funktion:
 Application.ProcessMessages
****************************************************************)
var
  Msg: TMsg;
begin
  while PeekMessage(Msg, hWnd, 0, 0, PM_REMOVE) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end;