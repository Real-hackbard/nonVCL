unit TDLLClass;

interface

uses
  Windows;

type
  PDllInfoVersion = ^TDllInfoVersion;
  TDllInfoVersion = packed record
    Build      : Word;
    Revision   : Word;
    Subversion : Word;
    MainVersion: Word;
  end;

type
  PDllInfoExportEntry = ^TDllInfoExportEntry;
  TDllInfoExportEntry = record
    Ordinal: WORD;
    Hint   : DWORD;
    Name   : string;
    VaAddr : DWORD;
    FwdName: string;
  end;


type
  TDLLInfo = class
  private
    FFilename: string;

    FFileHandle: THandle;
    FFMapObject: THandle;
    FViewOfFile: Pointer;

    FVersionInt: Int64;
    FVersionStr: string;

    FExportCount: Integer;
    FExportEntry: array of TDllInfoExportEntry;

    procedure MapFile;
    procedure UnmapFile;
    procedure ReadVersionInfo;
    procedure ReadExportDirectory;

    function GetExportrEnty(Index: Integer): TDllInfoExportEntry;
    procedure SetExportrEnty(Index: Integer; const Value: TDllInfoExportEntry);

  public
    constructor Create(Filename: String);
    destructor Destroy; override;

    property Version : String read FVersionStr;

    property ExportCount: Integer read FExportCount;
    property ExportEntry[Index: Integer]: TDllInfoExportEntry
      read GetExportrEnty write SetExportrEnty;
end;


implementation


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


////////////////////////////////////////////////////////////////////////////////
//
//  Constructor / Destructor
//

constructor TDLLInfo.Create(Filename: string);
begin
  FFilename := Filename;
  FFileHandle := INVALID_HANDLE_VALUE;
  FFMapObject := THandle(nil);
  FViewOfFile := nil;
  FExportCount := 0;
  SetLength(FExportEntry, 0);

  MapFile;
  if (FViewOfFile <> nil) then
  try

    ReadVersionInfo;
    ReadExportDirectory;

  finally
    UnmapFile;
  end;
end;

destructor TDLLInfo.Destroy;
begin
  inherited;

  UnmapFile;
  FExportCount := 0;
  SetLength(FExportEntry, 0);
  FFileHandle := INVALID_HANDLE_VALUE;
  SetLength(FFilename, 0);
end;


////////////////////////////////////////////////////////////////////////////////
//
//  File Mapping
//

procedure TDllInfo.MapFile;
begin
  FFileHandle := CreateFile(PChar(FFilename), GENERIC_READ, FILE_SHARE_READ,
    nil, OPEN_EXISTING, 0, THandle(nil));
//FViewOfFile := nil;
  if (FFileHandle <> INVALID_HANDLE_VALUE) then
  try
    FFMapObject := CreateFileMapping(FFileHandle, nil, PAGE_READONLY or
      SEC_COMMIT, 0, 0, nil);
    if (FFMapObject <> 0) then
    try
      FViewOfFile := MapViewOfFile(FFMapObject, FILE_MAP_READ, 0, 0, 0);
    finally
      if (nil = FViewOfFile) then
      begin
        CloseHandle(FFileHandle);
        FFileHandle := INVALID_HANDLE_VALUE;
      end;
    end;
  finally
    if (nil = FViewOfFile) then
    begin
      CloseHandle(FFileHandle);
      FFileHandle := INVALID_HANDLE_VALUE;
    end;
  end;
end;

procedure TDllInfo.UnmapFile;
begin
  if (FViewOfFile <> nil) then
  begin
    UnmapViewOfFile(FViewOfFile);
    FViewOfFile := nil;
  end;
  if (FFMapObject <> 0) then
  begin
    CloseHandle(FFMapObject);
    FFMapObject := 0;
  end;
  if (FFileHandle <> INVALID_HANDLE_VALUE) then
  begin
    CloseHandle(FFileHandle);
    FFileHandle := INVALID_HANDLE_VALUE;
  end;
end;


////////////////////////////////////////////////////////////////////////////////
//
//  Properties
//

function TDLLInfo.GetExportrEnty(Index: Integer): TDllInfoExportEntry;
begin
  Result := FExportEntry[Index];
end;

procedure TDLLInfo.SetExportrEnty(Index: Integer;
  const Value: TDllInfoExportEntry);
begin
  FExportEntry[Index] := Value;
end;


////////////////////////////////////////////////////////////////////////////////
//
//  Exports
//
//    Purpose: Read exported functions (file loaded with MapViewOfFile)
//

procedure TDLLInfo.ReadExportDirectory;
type
  PWordArray = ^TWordArray;
  TWordArray = array [Word] of Word;
  PDWordArray = ^TDWordArray;
  TDWordArray = array [Word] of DWORD;
  PImageSectionHeaderArray = ^TImageSectionHeaderArray;
  TImageSectionHeaderArray = array [Word] of TImageSectionHeader;
var
  NtHeaders: PImageNtHeaders;
  SectArray: PImageSectionHeaderArray;
  ExpDatDir: PImageDataDirectory;
  ExportDir: PImageExportDirectory;
  Functions: PDWordArray;
  FuncIndex: Integer;
  ExpEntry: TDllInfoExportEntry;
  Ordinals: PWordArray;
  OrdIndex: Integer;
  Names: PDWordArray;
  function RvaToVa(Rva: DWORD): Pointer;
  var
    Section: Integer;
  begin
    Result := nil;
    for Section := 0 to Integer(SectArray) do
      with SectArray[Section] do
        if (VirtualAddress <= Rva) and
          (Rva < VirtualAddress + SizeOfRawData) then
        begin
          Result := Pointer(
            Cardinal(FViewOfFile) + PointerToRawData + (Rva - VirtualAddress));
          Break;
        end;
  end;
  function IsForwarderRva(Rva: DWORD): Boolean;
  begin
    Result := DWORD(Rva - ExpDatDir.VirtualAddress) < ExpDatDir.Size;
  end;
begin
  FExportCount := 0;
  SetLength(FExportEntry, 0);

  if (nil = FViewOfFile) then
    Exit;

  with PImageDosHeader(FViewOfFile)^ do
    if (IMAGE_DOS_SIGNATURE = e_magic) and (_lfanew > 0) then
      NtHeaders := PImageNtHeaders(Cardinal(FViewOfFile) + LongWord(_lfanew))
    else
      NtHeaders := PImageNtHeaders(FViewOfFile);
  with NtHeaders^, FileHeader, OptionalHeader do
    if (IMAGE_NT_SIGNATURE = Signature) and
      (SizeOfOptionalHeader >= SizeOf(TImageOptionalHeader) -
        SizeOf(DataDirectory) + SizeOf(TImageDataDirectory)) and
      (IMAGE_NT_OPTIONAL_HDR_MAGIC = Magic) then
    begin
      SectArray := PImageSectionHeaderArray(
        Cardinal(Addr(OptionalHeader)) + SizeOfOptionalHeader);
      ExpDatDir := Addr(DataDirectory[0]);
      ExportDir := RvaToVa(ExpDatDir.VirtualAddress);
    end
    else
      Exit;
  if (0 = ExpDatDir.Size) or (nil = ExportDir) then
    Exit;

  Functions := RvaToVa(Cardinal(ExportDir.AddressOfFunctions));
  Ordinals := RvaToVa(Cardinal(ExportDir.AddressOfNameOrdinals));
  Names := RvaToVa(Cardinal(ExportDir.AddressOfNames));
  if (nil = Functions) then
    Exit;

  SetLength(FExportEntry, ExportDir.NumberOfFunctions);
  for FuncIndex := 0 to ExportDir.NumberOfFunctions - 1 do
  begin
    if (0 = Functions[FuncIndex]) then
      Continue;
    ExpEntry.Ordinal := DWORD(FuncIndex) + ExportDir.Base;
    ExpEntry.Hint := FuncIndex;
    SetLength(ExpEntry.Name, 0);
    if (Ordinals <> nil) and (Names <> nil) then
      for OrdIndex := 0 to ExportDir.NumberOfNames - 1 do
        if Ordinals[OrdIndex] = FuncIndex then
        begin
          ExpEntry.Name := string(PAnsiChar(RvaToVa(Names[OrdIndex])));
          Break;
        end;
    if IsForwarderRva(Functions[FuncIndex]) then
    begin
      ExpEntry.VaAddr := 0;
      ExpEntry.FwdName := string(PAnsiChar(RvaToVa(Functions[FuncIndex])));
    end
    else
    begin
      ExpEntry.VaAddr := Functions[FuncIndex];
      SetLength(ExpEntry.FwdName, 0);
    end;
    FExportEntry[FExportCount] := ExpEntry;
    Inc(FExportCount);
  end;
end;


////////////////////////////////////////////////////////////////////////////////
//
//  Version Information
//
//

procedure TDLLInfo.ReadVersionInfo;
var
  VerInfoSize : DWord;
  VerValueSize: DWord;
  Dummy       : DWord;
  VerInfo     : Pointer;
  VerValue    : PVSFixedFileInfo;
begin
  FVersionInt := 0;
  SetLength(FVersionStr, 0);

  VerInfoSize := GetFileVersionInfoSize(PChar(FFilename), Dummy);
  if (VerInfoSize <> 0) then
  begin
    GetMem(VerInfo, VerInfoSize);
    try
      if GetFileVersionInfo(PChar(FFilename), 0, VerInfoSize, VerInfo) then
      begin
        if VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize) then
           with VerValue^ do
        begin
          FVersionInt := dwFileVersionMS;
          FVersionInt := (FVersionInt shl 32) or dwFileVersionLS;
          with PDllInfoVersion(@FVersionInt)^ do
            FVersionStr := Format('%d.%d.%d.%d',
              [MainVersion, Subversion, Revision, Build]);
        end;
      end;
    finally
      FreeMem(VerInfo, VerInfoSize);
    end;
  end;
end;


end.
