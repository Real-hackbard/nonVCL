//++IMPORTE
type
(*
  Declare function prototypes. The type FUNCTION can be called
  Such function can be called later like any other.
*)
  TFNOneFunction = function(param1, param2, param3: Cardinal): integer;
  TFNOneFunction_CDECL = function(param1, param2, param3: Cardinal): integer;
    cdecl;
  TFNOneFunction_STDCALL = function(param1, param2, param3: Cardinal): integer;
    stdcall;
  TFNOneFunction_as_CDECL = function(param1, param2, param3: Cardinal): integer; cdecl;
  TFNOneFunction_CDECL_as_PASCAL = function(param1, param2, param3: Cardinal): integer;
  TFNOneFunction_STDCALL_as_PASCAL = function(param1, param2, param3: Cardinal): integer;
  TFNOneFunction_as_STDCALL = function(param1, param2, param3: Cardinal): integer; stdcall;
  TFNOneFunction_CDECL_as_STDCALL = function(param1, param2, param3: Cardinal): integer; stdcall;
  TFNOneFunction_STDCALL_as_CDECL = function(param1, param2, param3: Cardinal): integer; cdecl;
  TFNInitDLL = procedure(window: Cardinal);

var
(*
  Variable declarations for the functions. These can be called up like normal ones
  Functions and procedures.
  All addresses are initially initialized with NIL. Of course that's just possible
  for global variables. Local variables cannot be pre-initialized.
*)
  OneFunction: TFNOneFunction = nil;
  OneFunction_CDECL: TFNOneFunction_CDECL = nil;
  OneFunction_STDCALL_: TFNOneFunction_STDCALL = nil;
  OneFunction_as_CDECL: TFNOneFunction_as_CDECL = nil;
  OneFunction_CDECL_as_PASCAL: TFNOneFunction_CDECL_as_PASCAL = nil;
  OneFunction_STDCALL_as_PASCAL: TFNOneFunction_STDCALL_as_PASCAL = nil;
  OneFunction_as_STDCALL: TFNOneFunction_as_STDCALL = nil;
  OneFunction_CDECL_as_STDCALL: TFNOneFunction_CDECL_as_STDCALL = nil;
  OneFunction_STDCALL_as_CDECL: TFNOneFunction_STDCALL_as_CDECL = nil;
  InitDLL: TFNInitDLL = nil;

(*
  Pre-declare function dummy. This dummy then steps in when we
  Didn't get the address of a function. He is then called and gives
  a short error message.
*)
Function WhatIfNoEntry: Integer;
begin
// Fehlermeldung in dem Funktionsnamenfeld (ganz unten im Dialog) ausgeben
  SetDlgItemText(hdlg, IDC_EDIT15, @noentry[1]);
end;

(*
  This function gets the "entry points" i.e. the addresses of the functions
  we need.
  This function is only used by the dynamic variant.
*)
Procedure GetEntryPoints;
var
  lib:THandle;
begin
// DLL load
  lib := LoadLibrary(@szNameDLL[1]);
// Check handle. If it is 0, the loading was not successful
  case lib = 0 of
    TRUE:
      begin
// Loading not successful, so set the address of the dummy function...
        @OneFunction_CDECL := @whatifnoentry;
        @OneFunction := @whatifnoentry;
        @OneFunction_STDCALL_ := @whatifnoentry;
        @OneFunction_as_CDECL := @whatifnoentry;
        @OneFunction_as_STDCALL := @whatifnoentry;
        @OneFunction_STDCALL_as_PASCAL := @whatifnoentry;
        @OneFunction_CDECL_as_PASCAL := @whatifnoentry;
        @OneFunction_STDCALL_as_CDECL := @whatifnoentry;
        @OneFunction_CDECL_as_STDCALL := @whatifnoentry;
        @initDLL := @whatifnoentry;
// ... and output the corresponding error
        messagebox(0, @dll_notloaded[1], nil, 0);
      end;
    else
    begin
// We need the address of three functions and assign them to the different ones
// functional prototypes
      @OneFunction := GetProcAddress(lib, @szNameOneFunction[1]);
      if not Assigned(OneFunction) then @OneFunction := @whatifnoentry;
      @OneFunction_CDECL := GetProcAddress(lib, @szNameOneFunction_CDECL[1]);
      if not Assigned(OneFunction_CDECL) then @OneFunction_CDECL := @whatifnoentry;
      @OneFunction_STDCALL_ := GetProcAddress(lib, @szNameOneFunction_STDCALL[1]);
      if not Assigned(OneFunction_STDCALL_) then @OneFunction_STDCALL_ := @whatifnoentry;
// Initialization routine
      @InitDLL := GetProcAddress(lib, 'initDLL');
      if not Assigned(InitDLL) then @initDLL := @whatifnoentry;
// And set the remaining function addresses accordingly. They are already known
      @OneFunction_as_CDECL := @OneFunction;
      @OneFunction_as_STDCALL := @OneFunction;
      @OneFunction_CDECL_as_PASCAL := @OneFunction_CDECL;
      @OneFunction_CDECL_as_STDCALL := @OneFunction_CDECL;
      @OneFunction_STDCALL_as_PASCAL :=@OneFunction_STDCALL_;
      @OneFunction_STDCALL_as_CDECL := @OneFunction_STDCALL_;
    end;
  end;
end;
//--IMPORT

