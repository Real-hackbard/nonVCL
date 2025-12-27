unit RamInfo;

interface

uses windows;

type TRAMInfo = class
  private
    FTotalMemory : Int64;
    FAvailMemory : Int64;
    FTotalPageFile : Int64;
    FAvailPageFile : Int64;
    FUsedmemory : DWORD;
    procedure GetTotalMemory;
    procedure GetAvailMemory;
    procedure GetTotalPageFile;
    procedure GetAvailPageFile;
    procedure GetUsedMemory;
  public
    constructor create;
    property TotalMemory: Int64 read FTotalMemory;
    property AvailMemory: Int64 read FAvailMemory;
    property TotalPageFile: Int64 read FTotalPageFile;
    property AvailPageFile: Int64 read FAvailPageFile;
    property UsedMemory: DWORD read FUsedMemory;
  end;

implementation

constructor TRAMInfo.create;
begin
   GetTotalMemory;
   GetAvailMemory;
   GetTotalPageFile;
   GetAvailPageFile;
   GetUsedMemory;
end;

procedure TRAMInfo.GetTotalMemory;
var
  Memory : TMemoryStatus;
begin
  Memory.dwLength := SizeOf(Memory);
  GlobalMemoryStatus(Memory);
  FTotalMemory := Memory.dwTotalPhys;
end;

procedure TRAMInfo.GetAvailMemory;
var
  Memory : TMemoryStatus;
begin
  Memory.dwLength := SizeOf(Memory);
  GlobalMemoryStatus(Memory);
  FAvailMemory:= Memory.dwAvailPhys;
end;

procedure TRAMInfo.GetTotalPageFile;
var
  Memory : TMemoryStatus;
begin
  Memory.dwLength := SizeOf(Memory);
  GlobalMemoryStatus(Memory);
  FTotalPageFile := Memory.dwTotalPageFile;
end;

procedure TRAMInfo.GetAvailPageFile;
var
  Memory : TMemoryStatus;
begin
  Memory.dwLength := SizeOf(Memory);
  GlobalMemoryStatus(Memory);
  FAvailPageFile := Memory.dwAvailPageFile;
end;

procedure TRAMInfo.GetUsedMemory;
var
 Memory : TMemoryStatus;
begin
  Memory.dwLength := SizeOf(Memory);
  GlobalMemoryStatus(Memory);
  FUsedMemory := Memory.dwMemoryLoad;
end;

end.
