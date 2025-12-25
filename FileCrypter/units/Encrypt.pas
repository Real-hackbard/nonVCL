unit Encrypt;

interface

uses
  Windows,
  Messages,
  MpuTools,
  Exceptions,
  Classes,
  DECUtil,
  DECCipher,
  DECHash,
  DECFmt,
  DECRandom;

const
  FCM_DELFILE_START = WM_USER + 1;
  FCM_DELFILE_PROG  = WM_USER + 2;
  FCM_DELFILE_END   = WM_USER + 3;

type
  PByteArray = ^TByteArray;
  TByteArray = array[0..32767] of Byte;
  TAction = (paEncrypt, paDecrypt, paDelFile);

type
  TOnProgress = procedure(Sender: TObject; PercentDone: Integer) of object;
  TOnShredderStart = procedure(Sender: TObject) of object;
  TOnShredderProgress = procedure(Sender: TObject; PercentDone: Cardinal) of
    object;
  TOnShredderPass = procedure(Sender: TObject; Pass: Cardinal; PassCount: Cardinal) of object;
  TOnShredderFinish = procedure(Sender: TObject) of object;
  TEncrypt = class(TInterfacedObject, IDECProgress)
  private
    FParent: THandle;
    FSrcFilename: string;
    FDestFilename: string;
    FPwd: string;
    FDelSourceFile: Boolean;
    FPassCount: Cardinal;
    FOnProgress: TOnProgress;
    FOnShredderStart: TOnShredderStart;
    FOnShredderFinish: TOnShredderFinish;
    FOnShredderProgress: TOnShredderProgress;
    FOnShredderPass: TOnShredderPass;
    function GetSrcFilename: string;
    procedure SetSrcFilename(const Value: string);
    function GetDestFilename: string;
    procedure SetDestFilename(const Value: string);
    function GetPwd: string;
    procedure SetPwd(const Value: string);
    function FileShredder_Gutmann(FileName: WideString): Boolean;
    procedure Process(const Min, Max, Pos: Int64); stdcall;
  public
    constructor Create;
    destructor destroy; override;
    property Parent: THandle read FParent write FParent;
    property SrcFilename: string read GetSrcFilename write SetSrcFilename;
    property DestFilename: string read GetDestFilename write SetDestFilename;
    property Pwd: string read GetPwd write SetPwd;
    property DelSourceFile: Boolean read FDelSourceFile write FDelSourceFile;
    property PassCount: Cardinal read FPassCount write FPassCount;
    class function PwdQuality(const Pwd: string): Extended;
    property OnProgress: TOnProgress read FOnProgress write FOnProgress;
    property OnShredderStart: TOnShredderStart read FOnShredderStart write FOnShredderStart;
    property OnShredderFinish: TOnShredderFinish read FOnShredderFinish write FOnShredderFinish;
    property OnShredderProgress: TOnShredderProgress read FOnShredderProgress write FOnShredderProgress;
    property OnShredderPass: TOnShredderPass read FOnShredderPass write FOnShredderPass;
    procedure Encrypt;
    procedure Decrypt;
  end;

implementation

{ TEncrypt }

var
  ACipherClass      : TDECCipherClass = TCipher_Rijndael;
  ACipherMode       : TCipherMode = cmCFS8;
  AHashClass        : TDECHashClass = THash_SHA1;
  AKDFIndex         : LongWord = 1;

const
  MYBLOCKSIZE       = 1024;

destructor TEncrypt.destroy;
begin
  ProtectBinary(FPwd);
  inherited;
end;

function TEncrypt.GetSrcFilename: string;
begin
  Result := FSrcFilename;
end;

function TEncrypt.GetDestFilename: string;
begin
  Result := FDestFilename;
end;

function TEncrypt.GetPwd: string;
begin
  Result := FPwd;
end;

procedure TEncrypt.SetSrcFilename(const Value: string);
begin
  if FileExists(Value) then
    FSrcFilename := Value
  else
    raise Exception.CreateFmt('File %s does not exist.', [WideString(Value)]);
end;

procedure TEncrypt.SetDestFilename(const Value: string);
begin
  FDestFilename := Value;
end;

procedure TEncrypt.SetPwd(const Value: string);
begin
  FPwd := Value;
end;

procedure TEncrypt.Process(const Min, Max, Pos: Int64); stdcall;
begin
  if Assigned(OnProgress) then
    OnProgress(Self, Round(100 / (Max - Min) * (Pos - Min)));
end;

procedure TEncrypt.Encrypt;
var
  Salt, Key         : Binary;
  Source, Dest      : TStream;
begin
  if FSrcFilename = FDestFilename then
    raise Exception.Create('Source file and destination file are equal');
  try
    Source := TFileStream.Create(FSrcFilename, fmOpenRead or fmShareDenyNone);
    try
      Dest := TFileStream.Create(FDestFilename, fmCreate);
      try
        with ValidCipher(ACipherClass).Create, Context do
        try
          Salt := RandomBinary(16);
          Key := ValidHash(AHashClass).KDFx(FPwd, Salt, KeySize, TFormat_Copy, AKDFIndex);
          Mode := ACipherMode;
          Init(Key);
          // Store the salt in Dest first; it loads better in .Decrypt.
          Dest.Write(Salt[1], Length(Salt));
          EncodeStream(Source, Dest, Source.Size, Self);
        finally
          Free;
          ProtectBinary(Salt);
          ProtectBinary(Key);
        end;
      finally
        Dest.Free;
      end;
    finally
      Source.Free;
    end;
    if DelSourceFile then
      if not FileShredder_Gutmann(WideString(SrcFilename)) then
        raise Exception.Create(SysErrorMessage(GetLastError), GetLastError);
  except
    raise Exception.Create(SysErrorMessage(GetLastError), GetLastError);
  end;
end;

procedure TEncrypt.Decrypt;
var
  Salt, Key         : Binary;
  Source, Dest      : TStream;
begin
  if FSrcFilename = FDestFilename then
    raise Exception.Create('Source file and destination file are equal');
  try
    Source := TFileStream.Create(FSrcFilename, fmOpenRead or fmShareDenyNone);
    try
      Dest := TFileStream.Create(FDestFilename, fmCreate);
      try
        with ValidCipher(ACipherClass).Create, Context do
        try
          SetLength(Salt, 16);
          Source.Read(Salt[1], Length(Salt));
          Key := ValidHash(AHashClass).KDFx(FPwd, Salt, KeySize, TFormat_Copy, AKDFIndex);
          Mode := ACipherMode;
          Init(Key);
          DecodeStream(Source, Dest, Source.Size - Source.Position, Self);
        finally
          Free;
          ProtectBinary(Salt);
          ProtectBinary(Key);
        end;
      finally
        Dest.Free;
      end;
    finally
      Source.Free;
    end;
    if DelSourceFile then
      if not FileShredder_Gutmann(WideString(SrcFilename)) then
        raise Exception.Create(SysErrorMessage(GetLastError), GetLastError);
  except
    raise;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Procedure : TEncrypt.PwdQuality
// Comment   : By Hagen Reddmann

class function TEncrypt.PwdQuality(const Pwd: string): Extended;

  function Entropy(P: PByteArray; L: Integer): Extended;
  var
    Freq            : Extended;
    I               : Integer;
    Accu            : array[Byte] of LongWord;
  begin
    Result := 0.0;
    if L <= 0 then
      Exit;
    FillChar(Accu, SizeOf(Accu), 0);
    for I := 0 to L - 1 do
      Inc(Accu[P[I]]);
    for I := 0 to 255 do
      if Accu[I] <> 0 then
      begin
        Freq := Accu[I] / L;
        Result := Result - Freq * (Ln(Freq) / Ln(2));
      end;
  end;

  function Differency: Extended;
  var
    S               : string;
    L, I            : Integer;
  begin
    Result := 0.0;
    L := Length(Pwd);
    if L <= 1 then
      Exit;
    SetLength(S, L - 1);
    for I := 2 to L do
      Byte(S[I - 1]) := Byte(Pwd[I - 1]) - Byte(Pwd[I]);
    Result := Entropy(Pointer(S), Length(S));
  end;

  function KeyDiff: Extended;
  const
    Table           =
      '^1234567890ß´qwertzuiopü+asdfghjklöä#<yxcvbnm,.-°!"§$%&/()=?`QWERTZUIOPÜ*ASDFGHJKLÖÄ''>YXCVBNM;:_';
  var
    S               : string;
    L, I, J         : Integer;
  begin
    Result := 0.0;
    L := Length(Pwd);
    if L <= 1 then
      Exit;
    S := Pwd;
    UniqueString(S);
    for I := 1 to L do
    begin
      J := Pos(S[I], Table);
      if J > 0 then
        S[I] := Char(J);
    end;
    for I := 2 to L do
      Byte(S[I - 1]) := Byte(S[I - 1]) - Byte(S[I]);
    Result := Entropy(Pointer(S), L - 1);
  end;

const
  GoodLength        = 10.0; // good length of Passphrases
var
  L                 : Extended;
begin
  Result := Entropy(Pointer(Pwd), Length(Pwd));
  if Result <> 0 then
  begin
    Result := Result * (Ln(Length(Pwd)) / Ln(GoodLength));
    L := KeyDiff + Differency;
    if L <> 0 then
      L := L / 64;
    Result := Result * L;
    if Result < 0 then
      Result := -Result;
    if Result > 1 then
      Result := 1;
  end;
end;

function TEncrypt.FileShredder_Gutmann(FileName: WideString): Boolean;
  // Fileshredder function > Algorithmus Gutmann
  // http://en.wikipedia.org/wiki/Gutmann_method
  // http://www.cs.auckland.ac.nz/~pgut001/pubs/secure_del.html
  //

type
  TTrippleByte = packed array[1..3] of Byte;
  PTrippleByte = ^TTrippleByte;

const
  Mask              : array[5..31] of TTrippleByte = (
    ($55, $55, $55), ($AA, $AA, $AA), ($92, $49, $24), ($49, $24, $92),
    ($24, $92, $49), ($00, $00, $00), ($11, $11, $11), ($22, $22, $22),
    ($33, $33, $33), ($44, $44, $44), ($55, $55, $55), ($66, $66, $66),
    ($77, $77, $77), ($88, $88, $88), ($99, $99, $99), ($AA, $AA, $AA),
    ($BB, $BB, $BB), ($CC, $CC, $CC), ($DD, $DD, $DD), ($EE, $EE, $EE),
    ($FF, $FF, $FF), ($92, $49, $24), ($49, $24, $92), ($24, $92, $49),
    ($6D, $B6, $DB), ($B6, $DB, $6D), ($DB, $6D, $B6));

var
  S                 : WideString;
  H                 : THandle;
  Len               : LARGE_INTEGER;
  C                 : PWideChar;
  SectorSize, Pass, i: Integer;
  W                 : Cardinal;
  Pos, Sectors      : Int64;
  Buffer            : array of Byte;
  // MP  -->
  SchritteGesamt    : Cardinal;
  SchritteAktuell   : Cardinal;
  Prozent           : Cardinal;
  // <-- MP

begin
  if Assigned(OnShredderStart) then
    OnShredderStart(self);

  Result := False;

  // Expand directory
  S := FileName;
  SetLength(FileName, MAX_PATH);
  SetLength(FileName, GetFullPathNameW(PWideChar(S), MAX_PATH, @FileName[1], C));

  // Open the file (bypassing the file cache) and read its size.
  H := CreateFileW(PWideChar(S), GENERIC_WRITE, FILE_SHARE_READ, nil,
    OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN or FILE_FLAG_WRITE_THROUGH, 0);
  //If H = INVALID_HANDLE_VALUE Then Exit;
  Len.LowPart := Windows.GetFileSize(H, @Len.HighPart);
  if (Len.LowPart = INVALID_FILE_SIZE) and (GetLastError <> NO_ERROR) then
    Exit;

  try
    // Determine sector size for direct access
    S := FileName;
    while not GetDiskFreeSpaceW(PWideChar(S), W, Cardinal(SectorSize), W, W) do
    begin
      i := Length(S);
      while (i > 0) and not (S[i] in [WideChar(':'), WideChar('\')]) do
        Dec(i);
      if (i > 1) and (S[i] = '\') and (S[i - 1] <> ':') then
        Dec(i);
      if i = Length(S) then
      begin
        SectorSize := 512;
        Break;
      end;
      Delete(S, i + 1, MAX_PATH);
    end;
    Sectors := (Len.QuadPart + SectorSize - 1) div SectorSize;

    i := SectorSize;
    while i mod SizeOf(TTrippleByte) <> 0 do
      Inc(i, SectorSize);
    SetLength(Buffer, i);

    // MP -->
    SchritteGesamt := Sectors div (Length(Buffer) div SectorSize) * FPassCount;
    // <-- MP
    for Pass := 0 to FPassCount - 1 do
    begin
      if Assigned(OnShredderPass) then
        OnShredderPass(self, Pass + 1, FPassCount);
      // Fill write buffer
      for i := 0 to Length(Buffer) div SizeOf(TTrippleByte) - 1 do
        if (Pass < Low(Mask)) or (Pass > High(Mask)) then
        begin
          Buffer[i * SizeOf(TTrippleByte)] := Random(256);
          Buffer[i * SizeOf(TTrippleByte) + 1] := Random(256);
          Buffer[i * SizeOf(TTrippleByte) + 1] := Random(256);
        end
        else
          PTrippleByte(@Buffer[i * SizeOf(TTrippleByte)])^ := Mask[Pass];

      // Overwrite File
      SetFilePointer(H, 0, nil, FILE_BEGIN);
      Pos := 0;
      while Pos < Sectors do
      begin
        i := Min(Sectors - Pos, Length(Buffer) div Integer(SectorSize));
        if not WriteFile(H, Buffer[0], i * SectorSize, W, nil)
          or (Integer(W) <> i * SectorSize) then
          Exit;
        Inc(Pos, i);
        // MP -->
        if Assigned(OnShredderProgress) then
        begin
          SchritteAktuell := Pos div (Length(Buffer) div SectorSize) + Sectors div (Length(Buffer) div SectorSize) *
            Pass;
          Prozent := trunc((SchritteAktuell / SchritteGesamt) * 100);
          OnShredderProgress(self, Trunc(Prozent));
        end;
        // <-- MP
      end;
    end;
  finally
    CloseHandle(H);
  end;

  // Delete File
  result := DeleteFileW(PWideChar(FileName));
  // MP -->
  if Assigned(OnShredderFinish) then
    OnShredderFinish(self);
  // <-- MP
end;

constructor TEncrypt.Create;
begin
  FPassCount := 1;
end;

initialization
  RandomSeed; // initialisiere kryptographisch sicheren Zufallsgenerator in DECRandom.pas mit zufälligem Startwert
finalization

end.

