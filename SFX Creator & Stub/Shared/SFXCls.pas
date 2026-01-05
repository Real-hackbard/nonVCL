 {

   Stub
   File1
   File2
   File3
   ..
   Filen
   TOC
   TOCSize (Integer)
   StubFile size (Integer)

 }

unit SFXCls;

interface

uses
  Windows,
  MpuTools,
  Exceptions,
  FileContainerCls;

type
  TTOCEntry = packed record
    Filename: string[255];
    FileSize: Int64;
    OffSet: Int64;
  end;

  TOnAppendTOC = procedure(Sender: TObject) of object;
  TOnAppendFile = procedure(Sender: TObject; Index: Integer; FileObject: TFile) of object;
  TOnAppendingFile = procedure(Sender: TObject; FileObject: TFile; PercentDone: Integer) of object;
  TOnExtractFile = procedure(Sender: TObject; Index: Integer; FileObject: TFile) of object;
  TOnExtractingFile = procedure(Sender: TObject; FileObject: TFile; PercentDone: Integer) of object;

  TSFX = class(TObject)
  private
    FFilename: string;
    FStubFileSize: Integer;
    FRoot: string;
    FFileList: TFileContainer;
    FTOC: array of TTOCEntry;
    FCancel: Boolean;
    FOnAppendTOC: TOnAppendTOC;
    FOnAppendFile: TOnAppendFile;
    FOnAppendingFile: TOnAppendingFile;
    FOnExtractFile: TOnExtractFile;
    FOnExtractingFile: TOnExtractingFile;
    procedure CreateTOC;
  public
    constructor Create(Filename: string; Root: string; FileList: TFileContainer);
    procedure AppendFiles;
    procedure AppendTOC;
    procedure ReadTOC;
    procedure ExtractFiles;
    procedure CopyStub(Source, Dest: string);
    property Cancel: Boolean read FCancel write FCancel;
    property OnAppendTOC: TOnAppendTOC read FOnAppendTOC write FOnAppendTOC;
    property OnAppendFile: TOnAppendFile read FOnAppendFile write FOnAppendFile;
    property OnAppendingFile: TOnAppendingFile read FOnAppendingFile write FOnAppendingFile;
    property OnExtractFile: TOnExtractFile read FOnExtractFile write FOnExtractFile;
    property OnExtractingFile: TOnExtractingFile read FOnExtractingFile write FOnExtractingFile;
  end;

const
  BLOCKSIZE         = 32767;

implementation

{ TSFX }

procedure TSFX.AppendFiles;
var
  i                 : Integer;
  hStubFile         : THandle;
  hFileToAdd        : THandle;
  MemBuffer         : array[0..BLOCKSIZE - 1] of Byte;
  BytesToRead       : Int64;
  BytesRead         : Int64;
  BytesWritten      : Int64;
  TotalBytesWritten : Int64;

  function CalcBytesToRead(BytesRead, FileSize: Integer): Integer;
  var
    Size            : Integer;
  begin
    Size := FileSize - BytesRead;
    if Size < BLOCKSIZE then
      result := Size
    else
      result := BlockSize;
  end;

begin
  hStubFile := FileOpen(FFilename, fmOpenWrite);
  if hStubFile <> INVALID_HANDLE_VALUE then
  begin
    FileSeek(hStubFile, 0, 2); // Set filepointer to the end of the file
    for i := 0 to FFileList.Count - 1 do
    begin
      if FCancel then
        Break;
      if Assigned(OnAppendFile) then
        OnAppendFile(Self, i, FFileList.Items[i]);
      hFileToAdd := FileOpen(FFileList.Items[i].Filename, fmOpenRead);
      if hFileToAdd <> INVALID_HANDLE_VALUE then
      begin
        FileSeek(hFileToAdd, 0, 0);
        TotalBytesWritten := 0;
        BytesRead := 0;
        while TotalBytesWritten < FFileList.Items[i].FileSize do
        begin
          BytesToRead := CalcBytesToRead(BytesRead, FFileList.Items[i].FileSize);
          BytesRead := FileRead(hFileToAdd, MemBuffer, BytesToRead);
          BytesWritten := FileWrite(hStubFile, MemBuffer, BytesRead);
          TotalBytesWritten := TotalBytesWritten + BytesWritten;
          if Assigned(OnAppendingFile) then
            OnAppendingFile(Self, FFileList.Items[i], (TotalBytesWritten * 100) div FFileList.Items[i].FileSize);
        end;
        FileClose(hFileToAdd);
      end
      else
      begin
        raise Exception.CreateFmt('ErrorCode: %d' + #13#10 + '%s', [GetLastError, SysErrorMessage(GetLastError)]);
        Break;
      end;
    end;
    FileClose(hStubFile);
  end
  else
    raise Exception.CreateFmt('ErrorCode: %d' + #13#10 + '%s', [GetLastError, SysErrorMessage(GetLastError)]);
end;

procedure TSFX.AppendTOC;
var
  hFile             : THandle;
  TocSize           : Integer;
begin
  if Assigned(OnAppendTOC) then
    OnAppendTOC(self);
  hFile := FileOpen(FFilename, fmOpenWrite);
  if hFile <> INVALID_HANDLE_VALUE then
  begin
    FileSeek(hFile, 0, 2); // Set filepointer to the end of the file
    TocSize := length(FTOC) * SizeOf(TTOCEntry);
    FileWrite(hFile, FTOC[0], TocSize); // Append TOC
    FileWrite(hFile, TocSize, SizeOf(Integer)); // Append TOC size
    FileWrite(hFile, FStubFileSize, SizeOf(Integer));
    FileClose(hFile);
  end
  else
    raise Exception.CreateFmt('Errorcode: %d' + #13#10 + '%s', [GetLastError, SysErrorMessage(GetLastError)]);
end;

procedure TSFX.CopyStub(Source, Dest: string);
begin
  if not CopyFile(PChar(Source), PChar(Dest), False) then
    raise Exception.CreateFmt('Errorcode: %d' + #13#10 + '%s', [GetLastError, SysErrorMessage(GetLastError)]);
end;

constructor TSFX.Create(Filename: string; Root: string; FileList: TFileContainer);
begin
  FFilename := Filename;
  FStubFileSize := GetFileSize(ExtractFilepath(ParamStr(0)) + 'SFXStub.exe');
  FRoot := Root;
  FFileList := FileList;
  SetLength(FTOC, FFileList.Count);
  CreateTOC;
end;

procedure TSFX.CreateTOC;
var
  i                 : Integer;

  function StripRoot(Root, Filepath: string): string;
  var
    s               : string;
  begin
    s := FilePath;
    Delete(s, 1, length(Root));
    Result := s;
  end;

begin
  for i := 0 to FFileList.Count - 1 do
  begin
    FillChar(FTOC[i].Filename, 255, #0);
    FTOC[i].Filename := StripRoot(FRoot, FFileList.Items[i].Filename);
    FTOC[i].FileSize := FFileList.Items[i].FileSize;
    FTOC[i].OffSet := FFileList.Items[i].OffSet;
  end;
end;

procedure TSFX.ExtractFiles;
var
  hFile             : THandle;
  hFileToExtract    : THandle;
  i                 : Integer;

  MemBuffer         : array[0..BLOCKSIZE - 1] of Byte;
  BytesToRead       : Int64;
  BytesRead         : Int64;
  BytesWritten      : Int64;
  TotalBytesWritten : Int64;

  function CalcBytesToRead(BytesRead, FileSize: Integer): Integer;
  var
    Size            : Integer;
  begin
    Size := FileSize - BytesRead;
    if Size < BLOCKSIZE then
      result := Size
    else
      result := BlockSize;
  end;

begin
  hFile := FileOpen(FFilename, fmOpenRead);
  if hFile <> INVALID_HANDLE_VALUE then
  begin
    for i := 0 to FFileList.Count - 1 do
    begin
      if Assigned(OnExtractFile) then
        OnExtractFile(Self, i, FFileList.Items[i]);
      if ForceDirectories(DelBackSlash(FRoot) + ExtractFilepath(FFileList.Items[i].Filename)) then
      begin
        hFileToExtract := FileCreate(DelBackSlash(FRoot) + FFileList.Items[i].Filename);
        if hFileToExtract <> INVALID_HANDLE_VALUE then
        begin
          TotalBytesWritten := 0;
          BytesRead := 0;
          FileSeek(hFile, FStubFileSize + FFileList.Items[i].OffSet, 0);
          while TotalBytesWritten < FFileList.Items[i].FileSize do
          begin
             BytesToRead := CalcBytesToRead(BytesRead, FFileList.Items[i].FileSize);
             BytesRead := FileRead(hFile, MemBuffer, BytesToRead);
             BytesWritten := FileWrite(hFileToExtract, MemBuffer, BytesRead);
             TotalBytesWritten := TotalBytesWritten + BytesWritten;
             if Assigned(OnExtractingFile) then
               OnExtractingFile(Self, FFileList.Items[i], (TotalBytesWritten * 100) div FFileList.Items[i].FileSize);
             Sleep(100);
          end;
          FileClose(hFileToExtract);
        end
        else
        begin
          FileClose(hFile);
          FileClose(hFileToExtract);
          raise Exception.CreateFmt('Errorcode: %d' + #13#10 + '%s', [GetLastError, SysErrorMessage(GetLastError)]);
        end;
      end
      else
      begin
        FileClose(hFile);
        raise Exception.CreateFmt('Errorcode: %d' + #13#10 + '%s', [GetLastError, SysErrorMessage(GetLastError)]);
      end;
    end;
    FileClose(hFile);
  end
  else
    raise Exception.CreateFmt('Errorcode: %d' + #13#10 + '%s', [GetLastError, SysErrorMessage(GetLastError)]);
end;

procedure TSFX.ReadTOC;
var
  hFile             : THandle;
  TOCSize           : Integer;
  TOC               : array of TTOCEntry;
  i                 : Integer;
  FileObject        : TFile;
begin
  if FStubFileSize = GetFileSize(ParamStr(0)) then exit;
  hFile := FileOpen(FFilename, fmOpenRead);
  if hFile <> INVALID_HANDLE_VALUE then
  begin
    FileSeek(hFile, GetFileSize(FFilename) - SizeOf(Integer), 0);
    FileRead(hFile, FStubFileSize, SizeOf(Integer));
    FileSeek(hFile, GetFileSize(FFilename) - SizeOf(Integer) - SizeOf(Integer), 0);
    FileRead(hFile, TOCSize, SizeOf(Integer));
    FileSeek(hFile, GetFileSize(FFilename) - SizeOf(Integer) - SizeOf(Integer) - TOCSize, 0);
    SetLength(TOC, TocSize div SizeOf(TTOCEntry));
    FileRead(hFile, TOC[0], TOCSize);
    FileClose(hFile);

    for i := 0 to length(TOC) - 1 do
    begin
      FileObject := TFile.Create;
      FileObject.Filename := TOC[i].Filename;
      FileObject.FileSize := TOC[i].FileSize;
      FileObject.OffSet := TOC[0].OffSet;
      FFileList.Add(FileObject);
    end;
  end
  else
    raise Exception.CreateFmt('Errorcode: %d' + #13#10 + '%s', [GetLastError, SysErrorMessage(GetLastError)]);
end;

end.

