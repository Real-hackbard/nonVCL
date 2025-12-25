unit globals;

interface

uses
  Windows, SysUtils;

const
  APPNAME                = 'Ping';
  INFO_TEXT              = APPNAME + ' %s' + #13#10 + '%s' + #13#10#13#10 +
    'Copyright © Your Name' + #13#10#13#10 +
    'Ping Unit Copyright by Your Name or URL' +#13#10#13#10 +
    'Homepage: Your Homepage' + #13#10 +
    'Contact: Your eMail';
  COPYRIGHT              = 'Copyright © Your Name';
  HOMEPAGE               = 'Your mepage';

function GetVersionInfo(var VersionString, Description: string): DWORD;

implementation

(*
 * Procedure  : GetVersionInfo
 * Date       : 
 *)
function GetVersionInfo(var VersionString, Description: string): DWORD;
type
  PDWORDArr = ^DWORDArr;
  DWORDArr = array[0..0] of DWORD;
var
  VerInfoSize            : DWORD;
  VerInfo                : Pointer;
  VerValueSize           : DWORD;
  VerValue               : PVSFixedFileInfo;
  LangInfo               : PDWORDArr;
  LangID                 : DWORD;
  Desc                   : PChar;
  i                      : Integer;
begin
  result := 0;
  VerInfoSize := GetFileVersionInfoSize(PChar(ParamStr(0)), LangID);
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
            VersionString := Format('%d.%d.%d.%d', [dwFileVersionMS shr 16, dwFileVersionMS and $FFFF,
              dwFileVersionLS shr 16, dwFileVersionLS and $FFFF]);
          end;
        end
        else
          VersionString := '';
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
              if VerQueryValue(VerInfo, @Format('\StringFileInfo\%8.8x\FileDescription', [LangID])[1], Pointer(Desc),
                VerValueSize) then
                Description := Desc;
            end;
            (********************************************************************)
          end;
        end
        else
          Description := '';
      end;
    finally
      GlobalFree(THandle(VerInfo));
    end
    else // GlobalAlloc
      result := GetLastError;
  end
  else // GetFileVersionInfoSize
    result := GetLastError;
end;

end.
