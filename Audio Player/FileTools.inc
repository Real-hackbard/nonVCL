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

function CutPathname(s: string): string;
var
  i: integer;
begin
  result := s;
  for i := length(s) downto 1 do
    // Look for the backslash from the end. Once found, copy everything from the backslash onwards.
    if s[i] = '\' then
      begin
        result := copy(s, i + 1, length(s));
        // End after the first backslash
        break;
      end;
end;

function CutFilename(s: string): string;
var
  i: integer;
begin
  result := s;
  for i := length(s) downto 1 do
    // Search for the backslash starting at the end. Once found, copy everything up to and including the backslash.
    if s[i] = '\' then
      begin
        result := copy(s, 1, i);
        // End after the first backslash
        break;
      end;
end;

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

function putbinrestohdd(binresname, path: String): Boolean; 
var 
  hi, hg, ResSize, 
  SizeWritten, hFile : cardinal; 
begin 
  result := false; 
  hi := FindResource(hInstance, @binresname[1], 'BINRES'); 
  if hi <> 0 then 
  begin 
    hg := LoadResource(hInstance, hi); 
    if hg <> 0 then 
    begin 
      ResSize := SizeofResource(hInstance, hi); 
      hFile := CreateFile(@path[1], GENERIC_READ or GENERIC_WRITE, 
        FILE_SHARE_READ or FILE_SHARE_WRITE, nil, CREATE_ALWAYS, 
        FILE_ATTRIBUTE_ARCHIVE, 0); 
      if hFile <> INVALID_HANDLE_VALUE then 
      try 
        result := (WriteFile(hFile, LockResource(HG)^, ResSize, 
          SizeWritten, nil) and (SizeWritten = ResSize)); 
      finally 
        CloseHandle(hFile); 
      end; 
    end; 
  end; 
end;


// Get the 'link time stamp' of an portable executable image file (PE32)
// (written for Delphi 5, some types missing in Windows.pas of Delphi 4)
function GetImageLinkTimeStamp(const FileName: string): DWORD;
const
  INVALID_SET_FILE_POINTER = DWORD(-1);
  BorlandMagicTimeStamp = $2A425E19;  // Delphi 4-6 (and above?)
  FileTime1970: TFileTime = (dwLowDateTime:$D53E8000; dwHighDateTime:$019DB1DE);
type
  PImageSectionHeaders = ^TImageSectionHeaders;
  TImageSectionHeaders = array [Word] of TImageSectionHeader;
type
  PImageResourceDirectory = ^TImageResourceDirectory;
  TImageResourceDirectory = packed record
    Characteristics: DWORD;
    TimeDateStamp: DWORD;
    MajorVersion: Word;
    MinorVersion: Word;
    NumberOfNamedEntries: Word;
    NumberOfIdEntries: Word;
  end;
var
  FileHandle: THandle;
  BytesRead: DWORD;
  ImageDosHeader: TImageDosHeader;
  ImageNtHeaders: TImageNtHeaders;
  SectionHeaders: PImageSectionHeaders;
  Section: Word;
  ResDirRVA: DWORD;
  ResDirSize: DWORD;
  ResDirRaw: DWORD;
  ResDirTable: TImageResourceDirectory;
  FileTime: TFileTime;
begin
  Result := 0;
  // Open file for read access
  FileHandle := CreateFile(PChar(FileName), GENERIC_READ, FILE_SHARE_READ, nil,
    OPEN_EXISTING, 0, 0);
  if (FileHandle <> INVALID_HANDLE_VALUE) then
  try
    // Read MS-DOS header to get the offset of the PE32 header
    // (not required on WinNT based systems - but mostly available)
    if not ReadFile(FileHandle, ImageDosHeader, SizeOf(TImageDosHeader),
      BytesRead, nil) or (BytesRead <> SizeOf(TImageDosHeader)) or
      (ImageDosHeader.e_magic <> IMAGE_DOS_SIGNATURE) then
    begin
      ImageDosHeader._lfanew := 0;
    end;
    // Read PE32 header (including optional header
    if (SetFilePointer(FileHandle, ImageDosHeader._lfanew, nil, FILE_BEGIN) =
      INVALID_SET_FILE_POINTER) then
    begin
      Exit;
    end;
    if not(ReadFile(FileHandle, ImageNtHeaders, SizeOf(TImageNtHeaders),
      BytesRead, nil) and (BytesRead = SizeOf(TImageNtHeaders))) then
    begin
      Exit;
    end;
    // Validate PE32 image header
    if (ImageNtHeaders.Signature <> IMAGE_NT_SIGNATURE) then
    begin
      Exit;
    end;
    // Seconds since 1970 (UTC)
    Result := ImageNtHeaders.FileHeader.TimeDateStamp;

    // Check for Borland's magic value for the link time stamp
    // (we take the time stamp from the resource directory table)
    if (ImageNtHeaders.FileHeader.TimeDateStamp = BorlandMagicTimeStamp) then
    with ImageNtHeaders, FileHeader, OptionalHeader do
    begin
      // Validate Optional header
      if (SizeOfOptionalHeader < IMAGE_SIZEOF_NT_OPTIONAL_HEADER) or
        (Magic <> IMAGE_NT_OPTIONAL_HDR_MAGIC) then
      begin
        Exit;
      end;
      // Read section headers
      SectionHeaders :=
        GetMemory(NumberOfSections * SizeOf(TImageSectionHeader));
      if Assigned(SectionHeaders) then
      try
        if (SetFilePointer(FileHandle,
          SizeOfOptionalHeader - IMAGE_SIZEOF_NT_OPTIONAL_HEADER, nil,
          FILE_CURRENT) = INVALID_SET_FILE_POINTER) then
        begin
          Exit;
        end;
        if not(ReadFile(FileHandle, SectionHeaders^, NumberOfSections *
          SizeOf(TImageSectionHeader), BytesRead, nil) and (BytesRead =
          NumberOfSections * SizeOf(TImageSectionHeader))) then
        begin
          Exit;
        end;
        // Get RVA and size of the resource directory
        with DataDirectory[IMAGE_DIRECTORY_ENTRY_RESOURCE] do
        begin
          ResDirRVA := VirtualAddress;
          ResDirSize := Size;
        end;
        // Search for section which contains the resource directory
        ResDirRaw := 0;
        for Section := 0 to NumberOfSections - 1 do
        with SectionHeaders[Section] do
          if (VirtualAddress <= ResDirRVA) and
            (VirtualAddress + SizeOfRawData >= ResDirRVA + ResDirSize) then
          begin
            ResDirRaw := PointerToRawData - (VirtualAddress - ResDirRVA);
            Break;
          end;
        // Resource directory table found?
        if (ResDirRaw = 0) then
        begin
          Exit;
        end;
        // Read resource directory table
        if (SetFilePointer(FileHandle, ResDirRaw, nil, FILE_BEGIN) =
          INVALID_SET_FILE_POINTER) then
        begin
          Exit;
        end;
        if not(ReadFile(FileHandle, ResDirTable,
          SizeOf(TImageResourceDirectory), BytesRead, nil) and
          (BytesRead = SizeOf(TImageResourceDirectory))) then
        begin
          Exit;
        end;
        // Convert from DosDateTime to SecondsSince1970
        if DosDateTimeToFileTime(HiWord(ResDirTable.TimeDateStamp),
          LoWord(ResDirTable.TimeDateStamp), FileTime) then
        begin
          // FIXME: Borland's linker uses the local system time
          // of the user who linked the executable image file.
          // (is that information anywhere?)
          Result := (ULARGE_INTEGER(FileTime).QuadPart -
            ULARGE_INTEGER(FileTime1970).QuadPart) div 10000000;
        end;
      finally
        FreeMemory(SectionHeaders);
      end;
    end;
  finally
    CloseHandle(FileHandle);
  end;
end;
