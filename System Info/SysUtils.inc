{-----------------------------------------------------------------------------
 Filename : SysUtils.inc
 Author   : Michael Puff
 Contents : needed SysUtils-Code
-----------------------------------------------------------------------------}

{-----------------------------------------------------------------------------
  Procedure : LowerCase
  Purpose   : converts charcters of a stringt into lowercase
  Arguments : const S: string
  Result    : string
-----------------------------------------------------------------------------}
function LowerCase(const S: string): string;
var
  Ch: Char;
  L: Integer;
  Source, Dest: PChar;
begin
  L := Length(S);
  SetLength(Result, L);
  Source := Pointer(S);
  Dest := Pointer(Result);
  while L <> 0 do
  begin
    Ch := Source^;
    if (Ch >= 'A') and (Ch <= 'Z') then Inc(Ch, 32);
    Dest^ := Ch;
    Inc(Source);
    Inc(Dest);
    Dec(L);
  end;
end;

function StrToInt(s: string): Integer;
var
  code: integer;
begin
  val(s, result, code);
end;

function StrToFloat(s: string): Extended;
var
  code: integer;
begin
  val(s, result, code);
end;

function IntToStr(Int: int64): string;
begin
  Str(Int, result);
end;

function FloatToStr(Value: Extended; Width, Decimals: Integer): string;
begin
  Str(Value:Width:Decimals, result);
end;

{-----------------------------------------------------------------------------
  Procedure : ft2st
  Purpose   : Converts a filetime to a systemtime
  Arguments : ft: FILETIME
  Result    : String
-----------------------------------------------------------------------------}
function ft2st(ft: FILETIME): String;
var
  st  : TSYSTEMTIME;
  lft : TFILETIME;
  buf : array[0..MAX_PATH]of char;
begin
  st.wYear             := 1970;
  st.wMonth            := 1;
  st.wDayOfWeek        := 0;
  st.wDay              := 1;
  st.wHour             := 0;
  st.wMinute           := 0;
  st.wSecond           := 0;
  st.wMilliseconds     := 0;
  FileTimeToLocalFileTime(ft, lft);
  FileTimeToSystemTime(lft,st);
  if (GetTimeFormat(LOCALE_USER_DEFAULT, TIME_FORCE24HOURFORMAT, @st, nil, buf,
    sizeof(buf)) > 0) then
      Result := String(buf);
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

