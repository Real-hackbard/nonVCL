unit FileContainerCls;

interface

uses
  List;

type
  TFile = class(TObject)
  private
    FFilename: String;
    FFileSize: Int64;
    FOffset: Int64;
    function GetFilename: String;
    procedure SetFilename(const Value: String);
    function GetFileSize: Int64;
    procedure SetFileSize(const Value: Int64);
    function GetOffSet: Int64;
    procedure SetOffSet(const Value: Int64);
  public
    property Filename: String read GetFilename write SetFilename;
    property FileSize: Int64 read GetFileSize write SetFileSize;
    property OffSet: Int64 read GetOffSet write SetOffSet;
  end;

  TFileContainer = class(TList)
  private
    FFileList: TList;
    FOffSet: Int64;
    FTotalSize: Int64;
    function GetItem(Index: Integer): TFile;
    procedure SetItem(Index: Integer; FileObject: TFile);
  public
    constructor Create;
    destructor Destroy; override;
    property Items[Index: Integer]: TFile read GetItem write SetItem;
    procedure Add(FileObject: TFile);
    procedure Clear; override;
    function Count: Integer;
    property OffSet: Int64 read FOffSet write FOffSet;
    property TotalSize: Int64 read FTotalSize write FTotalSize;
  end;

implementation

{ TFile }

function TFile.GetFilename: String;
begin
  Result := FFilename;
end;

function TFile.GetFileSize: Int64;
begin
  Result := FFileSize;
end;

function TFile.GetOffSet: Int64;
begin
  Result := FOffset;
end;

procedure TFile.SetFilename(const Value: String);
begin
  FFilename := Value;
end;

procedure TFile.SetFileSize(const Value: Int64);
begin
  FFileSize := Value;
end;

procedure TFile.SetOffSet(const Value: Int64);
begin
  FOffset := Value;
end;

{ TFileContainer }

procedure TFileContainer.Add(FileObject: TFile);
begin
  FTotalSize := FTotalSize + FileObject.FFileSize;
  if Self.Count = 0 then
    FOffSet := 0
  else
   FOffSet := FOffSet + Self.Items[Self.Count - 1].FFileSize;
  FileObject.FOffset := FOffSet;
  FFileList.Add(FileObject);
end;

procedure TFileContainer.Clear;
var
  i: Integer;
begin
  for i := 0 to FFileList.Count - 1 do
    TObject(FFileList.Items[i]).Free;
  FFileList.Count := 0;
  FTotalSize := 0;
end;

function TFileContainer.Count: Integer;
begin
  Result := FFileList.Count;
end;

constructor TFileContainer.Create;
begin
  FTotalSize := 0;
  FOffSet := 0;
  FFileList := Tlist.Create;
end;

destructor TFileContainer.Destroy;
var
  i: Integer;
begin
  for i := 0 to FFileList.Count - 1 do
    TObject(FFileList.Items[i]).Free;
  FFileList.Free;
  inherited;
end;

function TFileContainer.GetItem(Index: Integer): TFile;
begin
  Result := FFileList.Items[Index];
end;

procedure TFileContainer.SetItem(Index: Integer; FileObject: TFile);
begin
  if Assigned(FileObject) then
    FFileList.Items[Index] := FileObject;
end;

end.
