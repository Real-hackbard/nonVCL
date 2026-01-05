unit MpuDriveTools;

interface

uses Windows, Messages;

type
  TStringArray = array of string;

const
  FFM_INIT               = WM_USER + 1976; // wParam: not used, lParam: not used
  FFM_MAXFOLDERS         = WM_USER + 1978; // wParam: CountFolders, lparam: not used;
  FFM_PROGRESS           = WM_USER + 1977; // wParam: Level, lParam: not used
  FFM_ONFILEFOUND        = WM_USER + 1974; // wParam: not used, lParam: Filename
  FFM_ONDIRFOUND         = WM_USER + 1975; // wParam: Level, lParam: Directory
  FFM_FINISH             = WM_USER + 1979; // wParam: not used, lParam: not used

type
  TFindFiles = class(TObject)
  private
    FHandle: THandle;
    FRootFolder: string;
    FMask: string;
    FRecurse: Boolean;
    FProgress: Boolean;
    FCntFolders: Integer;
    FiFolder: Integer;
    FLevel: Integer;
    procedure CountFolders(RootFolder: string; Recurse: Boolean);
    procedure Find(Handle: THandle; RootFolder: string; Mask: string; Recurse: Boolean = True);
  public
    constructor Create(Handle: THandle; RootFolder: string; Mask: string; Recurse: Boolean; Progress: Boolean);
    procedure Init;
    procedure FindFiles;
    class procedure Terminate;
    property Handle: THandle read FHandle write FHandle;
    property RootFolder: String read FRootFolder write FRootFolder;
    property Mask: String read FMask write FMask;
    property Recurse: Boolean read FRecurse write FRecurse;
    property Progress: Boolean read FProgress write FProgress;
    property NumberOfFolders: Integer read FCntFolders;
  end;

var
  FFTerminate: Boolean;

procedure GetLogicalDrives(var Drives: TStringArray; ReadyOnly: Boolean = True; WithLabels: Boolean = True);
function GetVolumeLabel(const Drive: string): string;

implementation

constructor TFindFiles.Create(Handle: THandle; RootFolder: string; Mask: string; Recurse: Boolean; Progress: Boolean);
begin
  FHandle := Handle;
  FRootFolder := RootFolder;
  FMask := Mask;
  FRecurse := Recurse;
  FProgress := Progress;
  FFTerminate := False;
  if FProgress then
    Init;
end;

procedure TFindFiles.Init;
begin
  FCntFolders := 0;
  FiFolder := 0;
  FLevel := 0;
  if FProgress then
  begin
    SendMessage(FHandle, FFM_INIT, 0, 0);
    CountFolders(FRootFolder, FRecurse);
    Sendmessage(FHandle, FFM_MAXFOLDERS, FCntFolders, 0);
  end;
end;

procedure TFindFiles.CountFolders(RootFolder: string; Recurse: Boolean);
var
  hFindFile              : THandle;
  wfd                    : TWin32FindData;
begin
  if RootFolder[length(RootFolder)] <> '\' then
    RootFolder := RootFolder + '\';
  ZeroMemory(@wfd, sizeof(wfd));
  wfd.dwFileAttributes := FILE_ATTRIBUTE_NORMAL;
  if Recurse then
  begin
    hFindFile := FindFirstFile(pointer(RootFolder + '*.*'), wfd);
    if hFindFile <> 0 then
    try
      repeat
        if wfd.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY = FILE_ATTRIBUTE_DIRECTORY then
        begin
          if (string(wfd.cFileName) <> '.') and (string(wfd.cFileName) <> '..') then
          begin
            CountFolders(RootFolder + wfd.cFileName, Recurse);
          end;
        end;
      until FindNextFile(hFindFile, wfd) = False;
      Inc(FCntFolders);
    finally
      Windows.FindClose(hFindFile);
    end;
  end;
end;

procedure TFindFiles.Find(Handle: THandle; RootFolder: string; Mask: string; Recurse: Boolean = True);
var
  hFindFile              : THandle;
  wfd                    : TWin32FindData;
begin
  if FFTerminate then
    Exit;
  Inc(FLevel);
  if RootFolder[length(RootFolder)] <> '\' then
    RootFolder := RootFolder + '\';
  ZeroMemory(@wfd, sizeof(wfd));
  wfd.dwFileAttributes := FILE_ATTRIBUTE_NORMAL;
  if Recurse then
  begin
    hFindFile := FindFirstFile(pointer(RootFolder + '*.*'), wfd);
    if hFindFile <> 0 then
    try
      repeat
        if wfd.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY = FILE_ATTRIBUTE_DIRECTORY then
        begin
          if (string(wfd.cFileName) <> '.') and (string(wfd.cFileName) <> '..') then
          begin
            SendMessage(Handle, FFM_ONDIRFOUND, FLevel, lParam(string(RootFolder + wfd.cFileName)));
            Find(Handle, RootFolder + wfd.cFileName, Mask, Recurse);
          end;
        end;
      until FindNextFile(hFindFile, wfd) = False;
      Inc(FiFolder);
      SendMessage(Handle, FFM_PROGRESS, FiFolder, 0);
    finally
      Windows.FindClose(hFindFile);
    end;
  end;
  hFindFile := FindFirstFile(pointer(RootFolder + Mask), wfd);
  if hFindFile <> INVALID_HANDLE_VALUE then
  try
    repeat
      if (wfd.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> FILE_ATTRIBUTE_DIRECTORY) then
      begin
        SendMessage(Handle, FFM_ONFILEFOUND, 0, lParam(string(RootFolder + wfd.cFileName)));
      end;
    until FindNextFile(hFindFile, wfd) = False;
  finally
    Windows.FindClose(hFindFile);
  end;
  Dec(FLevel);
end;

procedure TFindFiles.FindFiles;
begin
  Find(FHandle, FRootFolder, FMask, FRecurse);
  SendMessage(FHandle, FFM_FINISH, 0, 0);
end;

class procedure TFindFiles.Terminate;
begin
  FFTerminate := True;;
end;


////////////////////////////////////////////////////////////////////////////////
//
//  GetVolumeLabel
//

function GetVolumeLabel(const Drive: string): string;
var
  RootDrive              : string;
  Buffer                 : array[0..MAX_PATH + 1] of Char;
  FileSysFlags           : DWORD;
  MaxCompLength          : DWORD;
begin
  result := '';
  FillChar(Buffer, sizeof(Buffer), #0);
  if length(Drive) = 1 then
    RootDrive := Drive + ':\'
  else
    RootDrive := Drive;
  if GetVolumeInformation(PChar(RootDrive), Buffer, sizeof(Buffer), nil,
    MaxCompLength, FileSysFlags, nil, 0) then
  begin
    result := string(Buffer);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//
//  GetLogicalDrives
//

procedure GetLogicalDrives(var Drives: TStringArray; ReadyOnly: Boolean = True;
  WithLabels: Boolean = True);

  function DriveIsReady(const Drive: string): Boolean;
  var
    wfd                  : TWin32FindData;
    hFindData            : THandle;
  begin
    SetErrorMode(SEM_FAILCRITICALERRORS);
    hFindData := FindFirstFile(Pointer(Drive + '*.*'), wfd);
    if hFindData <> INVALID_HANDLE_VALUE then
    begin
      Result := True;
    end
    else
    begin
      Result := False;
    end;
    Windows.FindClose(hFindData);
    SetErrorMode(0);
  end;

var
  FoundDrives            : PChar;
  CurrentDrive           : PChar;
  len                    : DWord;
  cntDrives              : Integer;
begin
  cntDrives := 0;
  SetLength(Drives, 26);
  GetMem(FoundDrives, 255);
  len := GetLogicalDriveStrings(255, FoundDrives);
  if len > 0 then
  begin
    try
      CurrentDrive := FoundDrives;
      while CurrentDrive[0] <> #0 do
      begin
        if ReadyOnly then
        begin
          if DriveIsReady(string(CurrentDrive)) then
          begin
            if WithLabels then
              Drives[cntDrives] := CurrentDrive + ' [' +
                GetVolumeLabel(CurrentDrive) + ']'
            else
              Drives[cntDrives] := CurrentDrive;
            Inc(cntDrives);
          end;
        end
        else
        begin
          if WithLabels then
            Drives[cntDrives] := CurrentDrive + ' [' +
              GetVolumeLabel(CurrentDrive) + ']'
          else
            Drives[cntDrives] := CurrentDrive;
          Inc(cntDrives);
        end;
        CurrentDrive := PChar(@CurrentDrive[lstrlen(CurrentDrive) + 1]);
      end;
    finally
      FreeMem(FoundDrives, len);
    end;
    SetLength(Drives, cntDrives);
  end;
end;

end.

