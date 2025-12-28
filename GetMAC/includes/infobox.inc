function Format(fmt: string; params: array of const): string;
var
  pdw1, pdw2        : PDWORD;
  i                 : integer;
  pc                : PCHAR;
begin
  pdw1 := nil;
  if length(params) > 0 then
    GetMem(pdw1, length(params) * sizeof(Pointer));
  pdw2 := pdw1;
  for i := 0 to high(params) do
  begin
    pdw2^ := DWORD(PDWORD(@params[i])^);
    inc(pdw2);
  end;
  GetMem(pc, 1024 - 1);
  try
    ZeroMemory(pc, 1024 - 1);
    SetString(Result, pc, wvsprintf(pc, PCHAR(fmt), PCHAR(pdw1)));
  except
    Result := '';
  end;
  if (pdw1 <> nil) then
    FreeMem(pdw1);
  if (pc <> nil) then
    FreeMem(pc);
end;

function GetFileVersion(const Filename: string): string;
type
  PDWORDArr = ^DWORDArr;
  DWORDArr = array[0..0] of DWORD;
var
  VerInfoSize       : DWORD;
  VerInfo           : Pointer;
  VerValueSize      : DWORD;
  VerValue          : PVSFixedFileInfo;
  LangID            : DWORD;
begin
  result := '';
  VerInfoSize := GetFileVersionInfoSize(PChar(Filename), LangID);
  if VerInfoSize <> 0 then
  begin
    VerInfo := Pointer(GlobalAlloc(GPTR, VerInfoSize));
    if Assigned(VerInfo) then
    try
      if GetFileVersionInfo(PChar(ParamStr(0)), 0, VerInfoSize, VerInfo) then
      begin
        if VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize) then
        begin
          with VerValue^ do
          begin
            result := Format('%d.%d.%d.%d', [dwFileVersionMS shr 16, dwFileVersionMS and $FFFF,
              dwFileVersionLS shr 16, dwFileVersionLS and $FFFF]);
          end;
        end
        else
          result := '';
      end;
    finally
      GlobalFree(THandle(VerInfo));
    end;
  end;
end;

function GetFileInfo(const Filename, Info: string): string;
type
  PDWORDArr = ^DWORDArr;
  DWORDArr = array[0..0] of DWORD;
var
  VerInfoSize       : DWORD;
  VerInfo           : Pointer;
  VerValueSize      : DWORD;
  LangInfo          : PDWORDArr;
  LangID            : DWORD;
  pInfo             : PChar;
  i                 : Integer;
begin
  result := '';
  VerInfoSize := GetFileVersionInfoSize(PChar(Filename), LangID);
  if VerInfoSize <> 0 then
  begin
    VerInfo := Pointer(GlobalAlloc(GPTR, VerInfoSize));
    if Assigned(VerInfo) then
    try
      if GetFileVersionInfo(PChar(ParamStr(0)), 0, VerInfoSize, VerInfo) then
      begin
        // Description
        if VerQueryValue(VerInfo, '\VarFileInfo\Translation', Pointer(LangInfo), VerValueSize) then
        begin
          if (VerValueSize > 0) then
          begin
            // Divide by element size since this is an array
            VerValueSize := VerValueSize div sizeof(DWORD);
            // Number of language identifiers in the table
           (********************************************************************)
            for i := 0 to VerValueSize - 1 do
            begin
              // Swap words of this DWORD
              LangID := (LoWord(LangInfo[i]) shl 16) or HiWord(LangInfo[i]);
              // Query value ...
              if VerQueryValue(VerInfo, @Format('\StringFileInfo\%8.8x\' + Info, [LangID])[1], Pointer(pInfo),
                VerValueSize) then
                result := pInfo;
            end;
            (********************************************************************)
          end;
        end
        else
          result := '';
      end;
    finally
      GlobalFree(THandle(VerInfo));
    end
    else // GlobalAlloc
      result := '';
  end
  else // GetFileVersionInfoSize
    result := '';
end;

procedure InfoBox(hParent: THandle);

const
  URI               = 'https://github.com';
  COPYRIGHT         = 'Copyright © Your Name';

var
  MsgInfo           : TMsgBoxParams;
  s: String;
begin
  s := Format('%s - %s' + #13#10#13#10 + '%s' + #13#10 + '%s', [GetFileInfo(ParamStr(0), 'ProductName'),
    GetFileVersion(ParamStr(0)), COPYRIGHT, URI]);

  MsgInfo.cbSize := SizeOf(TMsgBoxParams);
  MsgInfo.hwndOwner := hParent;
  MsgInfo.hInstance := GetWindowLong(hParent, GWL_HINSTANCE);
  MsgInfo.lpszText := PChar(s);
  MsgInfo.lpszCaption := PChar(GetFileInfo(ParamStr(0), 'ProductName'));
  MsgInfo.dwStyle := MB_USERICON;
  MsgInfo.lpszIcon := MAKEINTRESOURCE(1);
  MessageBoxIndirect(MsgInfo);
end;