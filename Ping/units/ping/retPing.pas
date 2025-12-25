unit retPing;

interface
uses winsock, windows;


type
  USHORT = word;


  PIP_OPTION_INFORMATION = ^IP_OPTION_INFORMATION;
  IP_OPTION_INFORMATION = record
    ttl: UCHAR; //         'Time To Live
    Tos: UCHAR; //       'Timeout
    Flags: UCHAR; //        'option flags
    OptionsSize: UCHAR; //        '
    OptionsData: PUCHAR; //        '
  end;


  PICMP_ECHO_REPLY = ^ICMP_ECHO_REPLY;
  ICMP_ECHO_REPLY = record
    Address: cardinal; //        'replying address
    Status: ULONG; //        'reply status code
    RoundTripTime: ULONG; //        'round-trip time, in milliseconds
    datasize: USHORT; //        'reply data size. Always an Int.
    Reserved: USHORT; //        'reserved for future use
    DataPointer: Pointer; //        'pointer to the data in Data below
    Options: IP_OPTION_INFORMATION; // 'reply options, used in tracert
    ReturnedData: array[0..255] of char;
      // 'the returned data follows the reply message. The data string must be sufficiently large enough to hold the returned data.
  end;


  ttracertCBfunc = procedure(hop, ip: dword; rtt: integer); stdcall;


procedure tracert(destIp: dword; cbFunc: ttracertCBfunc);
function GetIPAddress(const HostName: string): string;
function ICMPPing(Ip: DWORD): boolean; // returns true or false
function ICMPPingRTT(Ip: DWORD): integer; // returns round trip time
function DNSNameToIp(host: string): DWORD; // returns ip-adress as 4byte variable
function PingDW(ip: dword): integer;


function IcmpCreateFile: THandle; stdcall; external 'icmp.dll';
function IcmpCloseHandle(icmpHandle: THandle): boolean; stdcall; external 'icmp.dll'
function IcmpSendEcho
  (IcmpHandle: THandle; DestinationAddress: In_Addr;
  RequestData: Pointer; RequestSize: Smallint;
  RequestOptions: pointer;
  ReplyBuffer: Pointer;
  ReplySize: DWORD;
  Timeout: DWORD): DWORD; stdcall; external 'icmp.dll';


function GetRTTAndHopCount(DestIpAddress: DWORD; HopCount: pointer; MaxHops: DWORD;
  RTT: pointer): boolean; stdcall; external 'iphlpapi.dll';


implementation


function GetIPAddress(const HostName: string): string;
var
  R                 : Integer;
  WSAData           : TWSAData;
  HostEnt           : PHostEnt;
  Host              : string;
  SockAddr          : TSockAddrIn;
begin
  Result := '';
  R := WSAStartup($0101, WSAData);
  if R = 0 then
  try
    Host := HostName;
    if Host = '' then
    begin
      SetLength(Host, MAX_PATH);
      GetHostName(@Host[1], MAX_PATH);
    end;
    HostEnt := GetHostByName(@Host[1]);
    if HostEnt <> nil then
    begin
      SockAddr.sin_addr.S_addr := Longint(PLongint(HostEnt^.h_addr_list^)^);
      Result := inet_ntoa(SockAddr.sin_addr);
    end;
  finally
    WSACleanup;
  end;
end;




function ICMPPing(Ip: DWORD): boolean;
var
  Handle            : THandle;
  DW                : DWORD;
  rep               : array[1..128] of byte;
begin
  result := false;
  Handle := IcmpCreateFile;
  if Handle = INVALID_HANDLE_VALUE then Exit;
  DW := IcmpSendEcho(Handle, in_addr(Ip), nil, 0, nil, @rep, 128, 0);
  Result := (DW <> 0);
  IcmpCloseHandle(Handle);
end;


function ICMPPingRTT(Ip: DWORD): integer;
// returns roundtriptime if successfull
// otherwise -1
// -2 if a invalid host is entered
var
  Handle            : THandle;
  DW                : DWORD;
  echo              : PICMP_ECHO_REPLY;


begin
  if (ip = 0) or (ip = $FFFFFFFF) then begin
    result := -2;
    exit;
  end;
  result := -1;
  Handle := IcmpCreateFile;
  if Handle = INVALID_HANDLE_VALUE then Exit;
  new(echo);
  DW := IcmpSendEcho(Handle, in_addr(Ip), nil, 0, nil, echo, sizeof(ICMP_ECHO_REPLY) + 8, 0);
  if (DW <> 0) and (echo^.Address = Ip) then
    Result := echo^.RoundTripTime;
  IcmpCloseHandle(Handle);
  dispose(echo);
end;


// the 2 functions below use the GetRttandHopCount API

function ping(host: string; var hopCount, RTT: DWORD; var ipAd: string): DWORD;
var
  ip                : DWORD;
begin
  result := 0;
  hopCount := 0;
  RTT := 0;
  ipAd := GetIPAddress(host);
  ip := inet_addr(@ipAd[1]);
  if IcmpPing(ip) then
    (if not GetRTTAndHopCount(ip, @hopCount, 30, @RTT) then result := GetLastError)
  else Result := GetLastError;
end;


function PingDW(ip: dword): integer;
var
  hopCount, RTT     : DWORD;
begin
  result := -1;
  if IcmpPing(ip) then
    if GetRTTAndHopCount(ip, @hopCount, 30, @RTT) then
      result := RTT;
end;


function DNSNameToIp(host: string): DWORD;
begin
  host := GetIPAddress(host);
  result := inet_addr(@host[1]);
end;


procedure tracert(destIp: dword; cbFunc: ttracertCBfunc);
const
  maxhops           = 30;
var
  h                 : thandle;
  hop, rtt, ip      : dword;
  s                 : string;
  ipo               : PIP_OPTION_INFORMATION;
  echo              : PICMP_ECHO_REPLY;
begin
  ip := 0;
  setlength(s, 32);
  fillchar(pointer(s)^, 32, ord('a'));
  new(ipo);
  new(echo);
  hop := 0;
  h := icmpCreateFile;
  while (ip <> destip) and (hop <= maxhops) do begin
    inc(hop);
    ipo.ttl := hop;
    if icmpSendEcho(h, in_addr(destip), @s[1], 32,
      ipo, echo, sizeof(ICMP_ECHO_REPLY) + 8, 512) = 1
      then begin
      ip := echo.address;
      rtt := echo.RoundTripTime;
      cbfunc(hop, ip, rtt);
    end
    else begin
      ip := echo^.Address;
      cbfunc(hop, ip, -1);
    end;
  end;
  icmpCloseHandle(h);
  dispose(ipo);
  dispose(echo);
end;
end.

