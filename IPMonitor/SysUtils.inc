//
// Include Datei SysUtils.inc
// Copyright (c) 2003 Michael Puff
//

////////////////////////////////////////////////////////////////////////////////
// Procedure : StrToInt
// Comment   : 

function StrToInt(s: string): Integer;
var
  code: integer;
begin
  val(s, result, code);
end;


////////////////////////////////////////////////////////////////////////////////
// Procedure : StrToFloat
// Comment   :

function StrToFloat(s: string): Extended;
var
  code: integer;
begin
  val(s, result, code);
end;


////////////////////////////////////////////////////////////////////////////////
// Procedure : IntToStr
// Comment   : 

function IntToStr(Int64: integer): string;
begin
  Str(Int64, result);
end;


////////////////////////////////////////////////////////////////////////////////
// Procedure : FloatToStr
// Comment   : 

function FloatToStr(Value: Extended; Width, Decimals: Integer): string;
begin
  Str(Value:Width:Decimals, result);
end;


////////////////////////////////////////////////////////////////////////////////
// Procedure : Format
// Comment   : Formats a string according to the formatdiscriptors 

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


