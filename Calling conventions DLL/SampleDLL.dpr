library SampleDLL;
uses
  Windows,
  Messages;

{$INCLUDE .\Include\CompilerSwitches.pas}
{$INCLUDE .\Include\Constants.pas}
{$INCLUDE .\Include\Common.pas}

var hwnd: Cardinal = 0;

function OneFunction(param1, param2, param3: Cardinal): integer;
begin
  try
// Outputting what we received in the appropriate order.
    SetOutput_(hwnd, param1, param2, param3, szNameOneFunction, true);
  except
    result := hwnd;
  end;
end;

function OneFunction_CDECL(param1, param2, param3: Cardinal): integer; cdecl;
begin
  try
// Outputting what we received in the appropriate order.
    SetOutput_(hwnd, param1, param2, param3, szNameOneFunction_CDECL, true);
  except
    result := hwnd;
  end;
end;

function OneFunction_STDCALL_(param1, param2, param3: Cardinal): integer; stdcall;
begin
  try
// Outputting what we received in the appropriate order.
    SetOutput_(hwnd, param1, param2, param3, szNameOneFunction_STDCALL, true);
  except
    result := hwnd;
  end;
end;

procedure initDLL(window: Cardinal);
begin
// Let's remember the window of the main application in order to realize the output later.
  hwnd := window;
end;

exports
// OneFunction is exported with the name "OneFunction" and an as yet unknown index.
  OneFunction,
// OneFunction_CDECL is exported as "OneFunction_CDECL" with index 2.
  OneFunction_CDECL index 2,
// OneFunction_STDCALL_ is exported as "OneFunction_STDCALL" with index 3.
  OneFunction_STDCALL_ index 3 name szNameOneFunction_STDCALL,
// initDLL is exported with an empty name and index 100
  initDLL index 100 name '', // just as evidence for functions without names
// initDLL is exported with the name "initDLL" and an as yet unknown index.
  initDLL;

end.

