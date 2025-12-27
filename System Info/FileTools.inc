{-----------------------------------------------------------------------------
  Procedure : FileExists
  Purpose   : Checks if the given file exists
  Arguments : const FileName: string; dir: boolean = false
  Result    : Boolean
-----------------------------------------------------------------------------}
function FileExists(const FileName: string; dir: boolean = false): Boolean;
var
  hidate, lodate: word;
  Handle: THandle;
  FindData: TWin32FindData;
  LocalFileTime: TFileTime;

type
  LongRec = packed record
    Lo, Hi: Word;
  end;

  function SubFileExists: Boolean;
  begin
    FileTimeToLocalFileTime(FindData.ftLastWriteTime, LocalFileTime);
    result := FileTimeToDosDateTime(LocalFileTime, HiDate, LoDate);
  end;
begin
  result := false;
  Handle := FindFirstFile(PChar(FileName), FindData);
  if Handle <> INVALID_HANDLE_VALUE then
  begin
    Windows.FindClose(Handle);
    case dir of
      TRUE: if (FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) <> 0 then result := SubFileExists;
      FALSE: if (FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) = 0 then result := SubFileExists;
    end;
  end;
end;

{-----------------------------------------------------------------------------
  Procedure : CutPathname
  Purpose   : Returns the filename without the path
  Arguments : s: string
  Result    : string
-----------------------------------------------------------------------------}
function CutPathname(s: string): string;
var
  i: integer;
begin
  result := s;
  for i := length(s) downto 1 do
    // Von hinten den Backslash suchen. Wenn gefunden alles ab Backslash kopieren
    if s[i] = '\' then
      begin
        result := copy(s, i + 1, length(s));
        // Nach dem ersten Backslash beenden
        break;
      end;
end;

{-----------------------------------------------------------------------------
  Procedure : CutFilename
  Purpose   : Returns the path without the filename
  Arguments : s: string
  Result    : string
-----------------------------------------------------------------------------}
function CutFilename(s: string): string;
var
  i: integer;
begin
  result := s;
  for i := length(s) downto 1 do
    // Von hinten den Backslash suchen. Wenn gefunden alles bis inkl. Backslash kopieren
    if s[i] = '\' then
      begin
        result := copy(s, 1, i);
        // Nach dem ersten Backslash beenden
        break;
      end;
end;

{-----------------------------------------------------------------------------
  Procedure : ChangeFileExt
  Purpose   : Changes the fileextension
  Arguments : const szFilename, szNewExt: string
  Result    : string
-----------------------------------------------------------------------------}
function ChangeFileExt(const szFilename, szNewExt: string): string;
var
  rpos : integer;
begin
  rpos := length(szFilename);
  if(pos('.',szFilename) > 0) then
    while(szFilename[rpos] <> '.') and (rpos > 0) do
      dec(rpos);

  Result := copy(szFilename,1,rpos - 1) + szNewExt;
end;

{-----------------------------------------------------------------------------
  Procedure : GetFileSize
  Purpose   : Returns the size of the given file
  Arguments : szFile: PChar
  Result    : Cardinal
-----------------------------------------------------------------------------}
function GetFileSize(szFile: PChar): Cardinal;
var
  fFile: THandle;
  wfd: TWIN32FINDDATA;
begin
  result := 0;
  if not FileExists(szFile) then exit;
  fFile := FindFirstfile(pchar(szFile),wfd);
  if fFile = INVALID_HANDLE_VALUE then exit;
  result := (wfd.nFileSizeHigh*(MAXDWORD))+wfd.nFileSizeLow;
  windows.FindClose(fFile);
end;
