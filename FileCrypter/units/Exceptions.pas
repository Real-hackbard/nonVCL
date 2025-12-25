unit Exceptions;

interface

uses
  Windows;

type
  Exception = class
  protected
    FMsg: WideString;
    FCode: DWord;
  public
    constructor Create(const msg: WideString); overload;
    constructor Create(const msg: WideString; Errorcode: DWord); overload;
    constructor CreateFmt(Msg: WideString; const Args: array of TVarRec);
    property Message: WideString read FMsg;
    property Errorcode: DWord read FCode;
  end;

  EArgumentNull = class(Exception)
  public
    constructor Create(const parameter: WideString);
  end;

  EArgumentOutOfRange = class(Exception)
  public
    constructor Create(const parameter: WideString; const value);
  end;

  ENetAPIError = class(Exception)
  public
    constructor Create(Errorcode: DWord);
  end;

  EAbort = class(Exception);

  procedure Abort;

implementation

uses
  MpuTools;

////////////////////////////////////////////////////////////////////////////////
// Procedure : Format
// Comment   : Formats a widestring according to the formatdiscriptors
function FormatW(const S: WideString; const Args: array of const): WideString;
var
  StrBuffer2        : array[0..1023] of WideChar;
  A                 : array[0..15] of LongWord;
  i                 : Integer;
begin
  for i := High(Args) downto 0 do
    A[i] := Args[i].VInteger;
  wvsprintfW(@StrBuffer2, PWideChar(S), @A);
  Result := PWideChar(@StrBuffer2);
end;

function SysErrorMessage(ErrorCode: Integer): WideString;
var
  Len               : Integer;
  Buffer            : array[0..255] of WideChar;
begin
  Len := FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_ARGUMENT_ARRAY,
    nil, ErrorCode, 0, Buffer, SizeOf(Buffer), nil);
  SetString(Result, Buffer, Len);
end;


{ Exception }

procedure Abort;

  function ReturnAddr: Pointer;
  asm
          MOV     EAX,[EBP + 4]
  end;

begin
  raise EAbort.Create;
end;

constructor Exception.Create(const msg: WideString; Errorcode: DWord);
begin
  FMsg := msg;
  FCode := Errorcode;
end;

constructor Exception.Create(const msg: WideString);
begin
  FMsg := msg;
  FCode := DWord(-1);
end;

constructor Exception.CreateFmt(Msg: Widestring; const Args: array of TVarRec);
begin
  Create(FormatW(Msg, Args));
end;

{ EInvalidArgument }

constructor EArgumentNull.Create(const parameter: WideString);
begin
  inherited Create('Argument null or empty: ' + parameter);
end;

{ ENetAPIError }

constructor ENetAPIError.Create(Errorcode: DWord);
begin
  inherited Create(SysErrorMessage(Errorcode), Errorcode);
end;


{ EArgumentOutOfRange }

constructor EArgumentOutOfRange.Create(const parameter: WideString; const value);
begin
  inherited Create(FormatW('Argument out of range: ' + parameter, [Integer(value)]));
end;

end.
