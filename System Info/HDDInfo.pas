unit HDDInfo;

interface

uses windows, JwaWinIoctl;

type
  TDiskGeoArray = array of Int64;
  TPartitionsArray = array of string;
  TDiskNumArray = array of Integer;
  TStringArray = array of string;
  TIntArray = array of Integer;

type
  THDDInfo = class
  private
    FHDDsCount: DWORD;
    FCylinders: TDiskGeoArray;
    FTracksPerCylinder: TDiskGeoArray;
    FSectorsPerTrack: TDiskGeoArray;
    FBytesperSector: TDiskGeoArray;
    FDiskSize: TDiskGeoArray;
    FPartitions: TPartitionsArray;
    FDiskNumbers: TDiskNumArray;
    FPartOffSets: TDiskGeoArray;
    FPartLengths: TDiskGeoArray;
    FPartLabels: TStringArray;
    FPartSerials: TIntArray;
    FPartFileSystems: TStringArray;
    FPartTotalSpaces: TDiskGeoArray;
    FPartFreeSpaces: TDiskGeoArray;
    procedure GetHDDsCount;
    procedure GetDiskGeometry;
    procedure GetDiskSize;
    procedure GetPartitions;
    procedure DumpDiskExtents;
    procedure GetVolInformation;
    procedure GetPartSpace;
  public
    constructor create;
    property HDDsCount: DWORD read FHDDsCount;
    property Cylinders: TDiskGeoArray read FCylinders;
    property TracksPerCylinder: TDiskGeoArray read FTracksPerCylinder;
    property SectorsPerTrack: TDiskGeoArray read FSectorsPerTrack;
    property BytesPerSector: TDiskGeoArray read FBytesPerSector;
    property DiskSize: TDiskGeoArray read FDiskSize;
    property Partitions: TPartitionsArray read FPartitions;
    property DiskNumber: TDiskNumArray read FDiskNumbers;
    property PartOffSet: TDiskGeoArray read FPartOffSets;
    property PartLength: TDiskGeoArray read FPartLengths;
    property PartLabel: TStringArray read FPartLabels;
    property PartSerial: TIntArray read FPartSerials;
    property PartFilesystem: TStringArray read FPartFileSystems;
    property PartTotalSpace: TDiskGeoArray read FPartTotalSpaces;
    property PartFreeSpace: TDiskGeoArray read FPartFreeSpaces;
  end;

implementation

{$INCLUDE SysUtils.inc}

constructor THDDInfo.create;
begin
  GetHDDsCount;
  GetDiskGeometry;
  GetDiskSize;
  GetPartitions;
  DumpDiskExtents;
  GetVolInformation;
  GetPartSpace;
end;

procedure THDDInfo.GetHDDsCount;
var
  i            : Integer;
  Device       : string;
  hDevice      : Cardinal;
begin
  for i := 0 to 9 do
  begin
    Device := '\\.\PhysicalDrive' + IntToStr(i);
    hDevice := CreateFile(pointer(Device), 0, FILE_SHARE_READ or
      FILE_SHARE_WRITE,
      nil, OPEN_EXISTING, 0, 0);
    if hDevice <> INVALID_HANDLE_VALUE then
      Inc(FHDDsCount);
  end;
end;

procedure THDDInfo.GetDiskGeometry;
var
  i            : Integer;
  Device       : string;
  hDevice      : Cardinal;
  dg           : DISK_GEOMETRY;
  dummy        : DWORD;
begin
  setlength(FCylinders, FHDDsCount);
  setlength(FTracksPercylinder, FHDDsCount);
  setlength(FSectorsPerTrack, FHDDsCount);
  setlength(FBytesPerSector, FHDDsCount);
  for i := 0 to FHDDsCount - 1 do
  begin
    Device := '\\.\PhysicalDrive' + IntToStr(i);
    hDevice := CreateFile(pointer(Device), 0, FILE_SHARE_READ
      or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
    if hDevice <> INVALID_HANDLE_VALUE then
    begin
      if DeviceIOControl(hDevice, IOCTL_DISK_GET_DRIVE_GEOMETRY, nil, 0, @dg,
        sizeof(dg), dummy, nil) = true then
      begin
        FCylinders[i] := dg.Cylinders.QuadPart;
        FTracksPerCylinder[i] := dg.TracksPerCylinder;
        FSectorsPerTrack[i] := dg.SectorsPerTrack;
        FBytesPerSector[i] := dg.BytesPerSector;
      end
      else
      begin
        FCylinders[i] := 0;
        FTracksPerCylinder[i] := 0;
        FSectorsPerTrack[i] := 0;
        FBytesPerSector[i] := 0;
      end;
    end;
    CloseHandle(hDevice);
  end;
end;

procedure THDDInfo.GetDiskSize;
var
  i            : Integer;
begin
  setlength(FDiskSize, FHDDsCount);
  for i := 0 to FHDDsCount - 1 do
    FDiskSize[i] := FCylinders[i] * FTRacksPerCylinder[i] * FSectorsPerTrack[i]
      * BytesPerSector[i];
end;

procedure THDDInfo.GetPartitions;
var
  i, j         : Integer;
  drive        : string;
begin
  j := 0;
  for i := 67 to 90 do
  begin
    drive := chr(i) + ':';
    if GetDriveType(pointer(drive)) = DRIVE_FIXED then
    begin
      Inc(j);
      setlength(FPartitions, j);
      FPartitions[j - 1] := chr(i);
    end;
  end;
end;

procedure THDDInfo.DumpDiskExtents;
var
  VolumePath   : string;
  hVolume      : Cardinal;
  BytesWritten : DWORD;
  de           : VOLUME_DISK_EXTENTS;
  i, j         : Integer;
begin
  FDiskNumbers := nil;
  setlength(FDiskNumbers, length(FPartitions));
  setlength(FPartOffSets, length(FPartitions));
  setlength(FPartLengths, length(FPartitions));
  for i := 0 to length(FPartitions) - 1 do
  begin
    VolumePath := '\\.\' + FPartitions[i] + ':';
    hVolume := CreateFile(pointer(Volumepath), GENERIC_READ, FILE_SHARE_READ or
      FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
    if hVolume <> INVALID_HANDLE_VALUE then
    begin
      if DeviceIOControl(hVolume, IOCTL_VOLUME_GET_VOLUME_DISK_EXTENTS, nil, 0,
        @de, sizeof(de), BytesWritten, nil) = True then
      begin
        for j := 0 to de.NumberOfDiskExtents - 1 do
        begin
          FDiskNumbers[i] := de.extents[j].DiskNumber;
          FPartOffSets[i] := de.extents[j].StartingOffset.QuadPart;
          FPartLengths[i] := de.extents[j].ExtentLength.QuadPart;
        end;
      end;
      CloseHandle(hVolume);
    end;
  end;
end;

procedure THDDInfo.GetVolInformation;
var
  i            : Integer;
  drive        : string;
  VolumeNameBuffer,
    FileSystemNameBuffer: PChar;
  VolumeSerialNumber,
    FileSystemFlags,
    MaximumComponentLength: DWORD;
begin
  setlength(FPartLabels, length(FPartitions));
  setlength(FPartSerials, length(FPartitions));
  setlength(FPartFileSystems, length(FPartitions));
  GetMem(VolumeNameBuffer, 255);
  GetMem(FileSystemNameBuffer, 255);
  try
    for i := 0 to length(FPartitions) - 1 do
    begin
      drive := FPartitions[i] + ':\';
      GetVolumeInformation(PChar(drive), VolumeNameBuffer,
        {sizeof(VolumeNameBuffer)}255,
        @VolumeSerialNumber, MaximumComponentLength, FileSystemFlags,
        FileSystemNameBuffer, 255);
      FPartLabels[i] := string(VolumeNameBuffer);
      FPartSerials[i] := VolumeSerialNumber;
      FPartFileSystems[i] := FileSystemNameBuffer;
    end;
  finally
    FreeMem(VolumeNameBuffer);
    FreeMem(FileSystemNameBuffer);
  end;
end;

procedure THDDInfo.GetPartSpace;
var
  i            : Integer;
  drive        : string;
  FreeSpaceAvailable,
    TotalSpace : Int64;

begin
  setlength(FPartTotalSpaces, length(FPartitions));
  setlength(FPartFreeSpaces, length(FPartitions));
  for i := 0 to length(FPartitions) - 1 do
  begin
    drive := FPartitions[i] + ':\';
    GetDiskFreeSpaceEx(PChar(drive), FreeSpaceAvailable, TotalSpace, nil);
    FPartTotalSpaces[i] := TotalSpace;
    FPartFreeSpaces[i] := FreeSpaceAvailable;
  end;
end;

end.

