unit MpuIPHelpers;

interface

uses
  Windows,
  WinSock,
  SysUtils,
  Classes,
  IpExport,
  IpHlpApi;

function GetMACByIP(IP: string): string;
function GetMACByName(Name: string): string;
function GetMacAddr(IP: string; var MAC: string): Integer;
function GetIpByHost(Host: string): string;
function GetHostByIP(IPAddr: string): string;
procedure IpStrToBytes(IPStr: string; var b0: Byte; var b1: Byte; var b2: Byte; var b3: Byte);

implementation

resourcestring
  rsErrorTemplate = '%d: %s.';
  rsERROR_BAD_NET_NAME = 'ERROR_BAD_NET_NAME - The network name cannot be found.';
  rsERROR_BUFFER_OVERFLOW = 'ERROR_BUFFER_OVERFLOW - The file name is too long.';
  rsERROR_GEN_FAILURE = 'ERROR_GEN_FAILURE - A device attached to the system is not functioning. The destination IPv4 address could not be reached because it is not on the same subnet or the destination computer is not operating.';
  rsERROR_INVALID_PARAMETER = 'ERROR_INVALID_PARAMETER - One of the parameters is invalid.';
  rsERROR_INVALID_USER_BUFFER = 'INVALID_USER_BUFFER - The supplied user buffer is not valid for the requested operation. ';
  rsERROR_NOT_FOUND = 'ERROR_NOT_FOUND - Element not found.';
  rsERROR_NOT_SUPPORTED = 'ERROR_NOT_SUPPORTED - The SendARP function is not supported by the operating system running on the local computer.';

procedure IpStrToBytes(IPStr: string; var b0: Byte; var b1: Byte; var b2: Byte; var b3: Byte);
var
  sl: TStringList;
begin
  sl := TStringList.Create;
  try
    sl.Delimiter := '.';
    sl.DelimitedText := IPStr;
    b0 := StrToIntDef(sl[0], 0);
    b1 := StrToIntDef(sl[1], 0);
    b2 := StrToIntDef(sl[2], 0);
    b3 := StrToIntDef(sl[3], 0);
  finally
    sl.Free;
  end;
end;

function GetIpByHost(Host: string): string;
var
  TMPResult: string;
  WSA: TWSAData;
  H: PHostEnt;
begin
  if WSAStartUp($101, WSA) = 0 then
  begin
    H := GetHostByName(PChar(Host));
    if H <> nil then
    begin
      TMPResult := string(inet_ntoa(PInAddr(H^.h_addr_list^)^));
    end;
    WSACleanUp;
    if TMPResult <> '' then
      Result := TMPResult
    else
      Result := '0';
  end;
end;

function GetHostByIP(IPAddr: string): string;
var
  SockAddrIn: TSockAddrIn;
  HostEnt: PHostEnt;
  WSAData: TWSAData;
begin
  WSAStartup($101, WSAData);
  SockAddrIn.sin_addr.s_addr := inet_addr(PChar(IPAddr));
  HostEnt := gethostbyaddr(@SockAddrIn.sin_addr.S_addr, 4, AF_INET);
  if HostEnt <> nil then
    Result := StrPas(Hostent^.h_name)
  else
    Result := '';
end;

function GetMacAddr(IP: string; var MAC: string): Integer;
var
  DestIP: IPAddr;
  pMacAddr: PULong;
  AddrLen: ULong;
  MacAddr: array[0..5] of byte;
  p: PByte;
  i: integer;
  res: Integer;
begin
  DestIp := inet_addr(PChar(IP));
  pMacAddr := @MacAddr[0];
  AddrLen := SizeOf(MacAddr);

  res := SendARP(DestIP, 0, pMacAddr, AddrLen);
  if res = NO_ERROR then
  begin
    p := PByte(pMacAddr);
    for i := 0 to AddrLen - 1 do
    begin
      MAC := MAC + IntToHex(p^, 2) + '-';
      Inc(p);
    end;
    SetLength(MAC, length(MAC) - 1);
  end;

  Result := res;
end;

function GetMACByName(Name: string): string;
var
  IP: string;
  res: Integer;
  MAC: string;
  s: string;
begin
  IP := GetIpByHost(Name);
  res := GetMacAddr(IP, MAC);
  if res = 0 then
    Result := MAC
  else
  begin
    case res of
      ERROR_BAD_NET_NAME: s := Format(rsErrorTemplate, [res, rsERROR_BAD_NET_NAME]);
      ERROR_BUFFER_OVERFLOW: s := rsERROR_BUFFER_OVERFLOW;
      ERROR_GEN_FAILURE: s := rsERROR_GEN_FAILURE;
      ERROR_INVALID_PARAMETER: s := rsERROR_INVALID_PARAMETER;
      ERROR_INVALID_USER_BUFFER: s := rsERROR_INVALID_USER_BUFFER;
      ERROR_NOT_SUPPORTED: s := rsERROR_NOT_SUPPORTED;
    else
      s := SysErrorMessage(res);
    end;
    raise Exception.Create(s);
  end;
end;

function GetMACByIP(IP: string): string;
var
  res: Integer;
  MAC: string;
  s: string;
begin
  res := GetMacAddr(IP, MAC);
  if res = 0 then
    Result := MAC
  else
  begin
    case res of
      ERROR_BAD_NET_NAME: s := Format(rsErrorTemplate, [res, rsERROR_BAD_NET_NAME]);
      ERROR_BUFFER_OVERFLOW: s := rsERROR_BUFFER_OVERFLOW;
      ERROR_GEN_FAILURE: s := rsERROR_GEN_FAILURE;
      ERROR_INVALID_PARAMETER: s := rsERROR_INVALID_PARAMETER;
      ERROR_INVALID_USER_BUFFER: s := rsERROR_INVALID_USER_BUFFER;
      ERROR_NOT_SUPPORTED: s := rsERROR_NOT_SUPPORTED;
    else
      s := SysErrorMessage(res);
    end;
    raise Exception.Create(s);
  end;
end;

end.
