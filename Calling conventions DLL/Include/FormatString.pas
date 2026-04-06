{
function frmt(mformat: string; args: array of POINTER): string;
(*
  Functionality:
    This function wraps the wvsprintf() function provided by windows and
    resembles the behavior of C's printf().
    [GENERIC] Note, you have to cast the parameters in the provided array to
    _some_ pointer type (e.g. pointer, pchar, pdword).
*)
(****************************************************************
 function frmt
 Return value: String

 function:
 Wrapper for wvsprintf(). Formats a string accordingly
 the specifications in “mformat”.

 (ergänzend:)
  VERSION 3.1 of this function!
   according to PSDK 4/2000 there's no limit for the buffer
   according to PSDK 10/2000 and later the limit is 1024 byte!
 ****************************************************************)
var
  buf: array[0..$400 - 1] of char;
begin
  ZeroMemory(@buf[0], sizeof(buf));
  wvsprintf(@buf[0], @mformat[1], pchar(@args));
  SetString(result, pchar(@buf[0]), lstrlen(@buf[0]));
end;
}

(*
Eugen also did his own version of this, this is for your convenience and pre-
servation of this knowledge, only. Furthermore it is widely compatible with the
Format() function from SysUtils.pas, except that it can only handle strings up
to 1024 characters (output)

It may receive any type of variable (integer, float, string ...).

Slightly modified to get it compatible with Delphi 3!!!

[GENERIC]
*)

function Format(fmt: string; params: array of const): string;
var
  pdw1, pdw2: PDWORD;
  i: integer;
  pc: PCHAR;
begin
  pdw1 := nil;
  if High(params) >= 0 then
    GetMem(pdw1, (High(params) + 1) * sizeof(Pointer));
  pdw2 := pdw1;
  for i := 0 to High(params) do begin
    pdw2^ := PDWORD(@params[i])^;
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

