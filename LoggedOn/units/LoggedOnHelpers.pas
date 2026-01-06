unit LoggedOnHelpers;

interface

uses
  Windows,
  WinSock,
  MpuTools,
  Exceptions,
  IpHlpAPI;

const
  NERR_SUCCESS      = 0;

type
  NET_API_STATUS = DWORD;
  LMSTR = Windows.LPWSTR;
  IPAddr = Cardinal;

type
  TWKSTA_INFO_100 = packed record
    wki100_platform_id: DWORD;
    wki100_computername: LMSTR;
    wki100_langroup: LMSTR;
    wki100_ver_major: DWORD;
    wki100_ver_minor: DWORD;
  end;
  PWKSTA_INFO_100 = ^TWKSTA_INFO_100;

  TSERVER_INFO_101 = packed record
    sv101_platform_ID: DWORD;
    sv101_name: PWChar;
    sv101_version_major: DWORD;
    sv101_version_minor: DWORD;
    sv101_type: DWORD; // not yet defined here!
    sv101_comment: PWChar;
  end;
  PSERVER_INFO_101 = ^TSERVER_INFO_101;

  PTimeOfDayInfo = ^TTimeOfDayInfo;
  TTimeOfDayInfo = packed record
    tod_elapsedt: DWORD;
    tod_msecs: DWORD;
    tod_hours: DWORD;
    tod_mins: DWORD;
    tod_secs: DWORD;
    tod_hunds: DWORD;
    tod_timezone: Longint;
    tod_tinterval: DWORD;
    tod_day: DWORD;
    tod_month: DWORD;
    tod_year: DWORD;
    tod_weekday: DWORD;
  end;

function GetComputerOS(const ComputerName: WideString): string;
function GetComputerCommentW(const ComputerName: WideString): WideString;
function GetComputerIP(const ComputerName: string): string;
function GetComputerMAC(const IP: string): string;
function GetComputerTimeOfDay(const ComputerName: WideString): TTimeOfDayInfo;
function GetComputerLanGroup(const ComputerName: WideString): WideString;

function NetWkstaGetInfo(servername: PWideChar; level: DWORD; var bufptr: Pointer): NET_API_STATUS; stdcall;
function NetServerGetInfo(const servername: PWChar; level: DWORD; bufptr: Pointer): NET_API_STATUS; stdcall;
function NetRemoteTOD(UncServerName: LPCWSTR; BufferPtr: PBYTE): NET_API_STATUS; stdcall;
function NetApiBufferFree(Buffer: Pointer): NET_API_STATUS; stdcall;

implementation

const
  netapi32lib       = 'netapi32.dll';

function NetWkstaGetInfo; external netapi32lib name 'NetWkstaGetInfo';
function NetServerGetInfo; external netapi32lib name 'NetServerGetInfo';
function NetRemoteTOD; external netapi32lib Name 'NetRemoteTOD';
function NetApiBufferFree; external netapi32lib name 'NetApiBufferFree';

function GetComputerOS(const ComputerName: WideString): string;
var
  res               : DWORD;
  s                 : string;
  si                : Pointer;
  Major             : DWORD;
  Minor             : DWORD;
resourcestring
  rsErrorOSUnknown  = 'unknown';
begin
  si := nil;
  s := '';
  res := NetWkstaGetInfo(PWideChar(ComputerName), 101, si);
  if res = NERR_Success then
  begin
    Major := PWKSTA_INFO_100(si)^.wki100_ver_major;
    Minor := PWKSTA_INFO_100(si)^.wki100_ver_minor;
    if (Major = 4) and (Minor = 0) then
    begin
      s := 'Windows NT 4.0';
    end
    else if (Major = 5) and (Minor = 0) then
    begin
      s := 'Windows 2000';
    end
    else if (Major = 5) and (Minor = 1) then
    begin
      s := 'Windows XP';
    end
    else if (Major = 5) and (Minor = 2) then
    begin
      s := 'Windows 2003 Server Family';
    end
    else if (Major = 6) and (Minor = 0) then
      s := 'Windows Vista'
	else if (Major = 6) and (Minor = 1) then
      s := 'Windows 7'
    else
      s := rsErrorOSUnknown;

    NetApiBufferFree(si);
  end
  else
    s := rsErrorOSUnknown;
  result := s;
end;

function GetComputerCommentW(const ComputerName: WideString): WideString;
var
  err               : DWORD;
  si                : Pointer;
begin
  Result := '';
  si := nil;
  err := NetServerGetInfo(PWideChar(ComputerName), 101, @si);
  if err = NERR_Success then
  begin
    Result := PSERVER_INFO_101(si)^.sv101_comment;
  end
  else
    Exception.CreateFmt('ErrorCode %d', [err]);
  NetApiBufferFree(si);
end;

function GetComputerIP(const ComputerName: string): string;
var
  s                 : string;
  TMPResult         : string;
  WSA               : TWSAData;
  H                 : PHostEnt;
  P                 : PChar;
begin
  if pos('\\', ComputerName) > 0 then
    s := copy(ComputerName, 3, Length(ComputerName));

  if WSAStartUp($101, WSA) = 0 then
  begin
    H := GetHostByName(PChar(s));
    if H <> nil then
    begin
      P := inet_ntoa(PInAddr(H^.h_addr_list^)^);
      TMPResult := string(P);
    end
    else
      Exception.CreateFmt('ErrorCode: %d', [WSAGetLastError]);
    WSACleanUp;
    if TMPResult <> '' then
      Result := TMPResult
    else
      Result := '0';
  end;
end;

function GetComputerMAC(const IP: string): string;
var
  DestIP            : IPAddr;
  pMacAddr          : PULong;
  AddrLen           : ULong;
  MacAddr           : array[0..5] of byte;
  p                 : PByte;
  i                 : integer;
  err               : Integer;
begin
  Result := '';
  DestIp := inet_addr(PChar(IP));
  pMacAddr := @MacAddr[0];
  AddrLen := SizeOf(MacAddr);

  err := SendARP(DestIP, 0, pMacAddr, AddrLen);
  if err = NO_ERROR then
  begin
    p := PByte(pMacAddr);
    for i := 0 to AddrLen - 1 do
    begin
      Result := Result + IntToHex(p^, 2) + '-';
      Inc(p);
    end;
    SetLength(Result, length(Result) - 1);
  end
  else
    Exception.CreateFmt('ErrorCode: %d', [err]);
end;

function GetComputerTimeOfDay(const ComputerName: WideString): TTimeOfDayInfo;
var
  TimeOfDayInfo: PTimeOfDayInfo;
  err: DWORD;
begin
  err := NetRemoteTOD(PWideChar(WideString(ComputerName)), PBYTE(@TimeOfDayInfo));
  if err = NERR_Success then
  begin
    with TimeOfDayInfo^ do
    begin
      Result := TimeOfDayInfo^;
      NetApiBufferFree(TimeOfDayInfo);
    end;
  end
  else
    Exception.CreateFmt('ErrorCode: %d', [err]);
end;

function GetComputerLanGroup(const ComputerName: WideString): WideString;
var
  err               : NET_API_STATUS;
  si                : Pointer;
begin
  err := NetWkStaGetInfo(PWideChar(ComputerName), 101, si);
  if err = NERR_Success then
  begin
    Result := PWKSTA_INFO_100(si)^.wki100_langroup;
  end
  else
    raise Exception.CreateFmt('ErrorCode: %d', [err]);
end;

end.
