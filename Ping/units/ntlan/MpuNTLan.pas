unit MpuNTLan;

interface

uses
  Windows, SysUtils, WinSock;

type
  LMSTR = Windows.LPWSTR;
  LPBYTE = Windows.PBYTE;
  NET_API_STATUS = DWORD;
  IPAddr = Cardinal;

  TStringDynArray = array of string;


type
  PWKSTA_INFO_100 = ^WKSTA_INFO_100;
  PWKSTA_INFO_101 = ^WKSTA_INFO_101;
  PWKSTA_INFO_102 = ^WKSTA_INFO_102;
  WKSTA_INFO_100 =
    packed record
    wki100_platform_id: DWord;
    wki100_computername: PWChar;
    wki100_langroup: PWChar;
    wki100_ver_major: DWord;
    wki100_ver_minor: DWord;
  end;
  WKSTA_INFO_101 =
    packed record
    wki101_platform_id: DWord;
    wki101_computername: PWChar;
    wki101_langroup: PWChar;
    wki101_ver_major: DWord;
    wki101_ver_minor: DWord;
    wki101_lanroot: PWChar;
  end;
  WKSTA_INFO_102 =
    packed record
    wki102_platform_id: DWord;
    wki102_computername: PWChar;
    wki102_langroup: PWChar;
    wki102_ver_major: DWord;
    wki102_ver_minor: DWord;
    wki102_lanroot: PWChar;
    wki102_logged_on_users: DWord;
  end;

type
  TSERVER_INFO_101 = packed record
    sv101_platform_ID: DWORD;
    sv101_name: PWChar;
    sv101_version_major: DWORD;
    sv101_version_minor: DWORD;
    sv101_type: DWORD; // not yet defined here!
    sv101_comment: PWChar;
  end;
  PSERVER_INFO_101 = ^TSERVER_INFO_101;

  SERVER_INFO_503 = record
    sv503_sessopens: Integer;
    sv503_sessvcs: Integer;
    sv503_opensearch: Integer;
    sv503_sizreqbuf: Integer;
    sv503_initworkitems: Integer;
    sv503_maxworkitems: Integer;
    sv503_rawworkitems: Integer;
    sv503_irpstacksize: Integer;
    sv503_maxrawbuflen: Integer;
    sv503_sessusers: Integer;
    sv503_sessconns: Integer;
    sv503_maxpagedmemoryusage: Integer;
    sv503_maxnonpagedmemoryusage: Integer;
    sv503_enablesoftcompat: BOOL;
    sv503_enableforcedlogoff: BOOL;
    sv503_timesource: BOOL;
    sv503_acceptdownlevelapis: BOOL;
    sv503_lmannounce: BOOL;
    sv503_domain: PWideChar;
    sv503_maxcopyreadlen: Integer;
    sv503_maxcopywritelen: Integer;
    sv503_minkeepsearch: Integer;
    sv503_maxkeepsearch: Integer;
    sv503_minkeepcomplsearch: Integer;
    sv503_maxkeepcomplsearch: Integer;
    sv503_threadcountadd: Integer;
    sv503_numblockthreads: Integer;
    sv503_scavtimeout: Integer;
    sv503_minrcvqueue: Integer;
    sv503_minfreeworkitems: Integer;
    sv503_xactmemsize: Integer;
    sv503_threadpriority: Integer;
    sv503_maxmpxct: Integer;
    sv503_oplockbreakwait: Integer;
    sv503_oplockbreakresponsewait: Integer;
    sv503_enableoplocks: BOOL;
    sv503_enableoplockforceclose: BOOL;
    sv503_enablefcbopens: BOOL;
    sv503_enableraw: BOOL;
    sv503_enablesharednetdrives: BOOL;
    sv503_minfreeconnections: Integer;
    sv503_maxfreeconnections: Integer;
  end;
  PSERVER_INFO_503 = ^SERVER_INFO_503;

const
  MAX_PREFERRED_LENGTH = DWORD(-1);

type
  _SHARE_INFO_0 = record
    shi0_netname: LMSTR;
  end;
  PSHARE_INFO_0 = ^_SHARE_INFO_0;

  _SHARE_INFO_502 = record
    shi502_netname: LMSTR;
    shi502_type: DWORD;
    shi502_remark: LMSTR;
    shi502_permissions: DWORD;
    shi502_max_uses: DWORD;
    shi502_current_uses: DWORD;
    shi502_path: LMSTR;
    shi502_passwd: LMSTR;
    shi502_reserved: DWORD;
    shi502_security_descriptor: PSECURITY_DESCRIPTOR;
  end;
  PSHARE_INFO_502 = ^_SHARE_INFO_502;

const
  NERR_Success      = 0;

const
  SV_TYPE_WORKSTATION = $00000001; // A LAN Manager workstation
  SV_TYPE_SERVER    = $00000002; // A LAN Manager server
  SV_TYPE_SQLSERVER = $00000004; // Any server running with Microsoft SQL Server
  SV_TYPE_DOMAIN_CTRL = $00000008; // Primary domain controller
  SV_TYPE_DOMAIN_BAKCTRL = $00000010; // Backup domain controller
  SV_TYPE_TIME_SOURCE = $00000020; // Server running the Timesource service
  SV_TYPE_AFP       = $00000040; // Apple File Protocol server
  SV_TYPE_NOVELL    = $00000080; // Novell server
  SV_TYPE_DOMAIN_MEMBER = $00000100; // LAN Manager 2.x domain member
  SV_TYPE_PRINTQ_SERVER = $00000200; // Server sharing print queue
  SV_TYPE_DIALIN_SERVER = $00000400; // Server running dial-in service
  SV_TYPE_XENIX_SERVER = $00000800; // Xenix server
  SV_TYPE_SERVER_UNIX = SV_TYPE_XENIX_SERVER; //
  SV_TYPE_NT        = $00001000; // Windows Server 2003, Windows XP, Windows 2000, or Windows NT
  SV_TYPE_WFW       = $00002000; // Server running Windows for Workgroups
  SV_TYPE_SERVER_MFPN = $00004000; // Microsoft File and Print for NetWare
  SV_TYPE_SERVER_NT = $00008000;
    // Windows Server 2003, Windows 2000 server, or Windows NT server that is not a domain controller
  SV_TYPE_POTENTIAL_BROWSER = $00010000; // Server that can run the browser service
  SV_TYPE_BACKUP_BROWSER = $00020000; // Server running a browser service as backup
  SV_TYPE_MASTER_BROWSER = $00040000; // Server running the master browser service
  SV_TYPE_DOMAIN_MASTER = $00080000; // Server running the domain master browser
  SV_TYPE_SERVER_OSF = $00100000; //
  SV_TYPE_SERVER_VMS = $00200000;
  SV_TYPE_WINDOWS   = $00400000; // Windows95 and above
  SV_TYPE_DFS       = $00800000; // Root of a DFS tree
  SV_TYPE_CLUSTER_NT = $01000000; // NT Cluster
  SV_TYPE_TERMINALSERVER = $02000000; // Terminal Server(Hydra)
  SV_TYPE_CLUSTER_VS_NT = $04000000; // NT Cluster Virtual Server Name
  SV_TYPE_DCE       = $10000000; // IBM DSS (Directory and Security Services) or equivalent
  SV_TYPE_ALTERNATE_XPORT = $20000000; // return list for alternate transport
  SV_TYPE_LOCAL_LIST_ONLY = $40000000; // Return local list only
  SV_TYPE_DOMAIN_ENUM = DWORD($80000000); // Primary domain
  SV_TYPE_ALL       = DWORD($FFFFFFFF); // handy for NetServerEnum2


function ToIP(I1, I2, I3, I4: Integer): Cardinal;
function IPToStr(Value: Cardinal): string;
function IPToMAC(IP: string): string;
function IPAddrToName(IPAddr: string): string;
function ListSharedFolders(const ServerName: PWideChar): TStringDynArray;

function GetRemoteOS(const Computer: WideString; var Version: string): DWORD;
function GetServerType(const Computer: WideString; var SV_Type: DWORD): DWORD;
function GetDomainName(const Computername: string): string;
function GetServerComment(const Computer: WideString; var comment: string): DWORD;
//function ServerTypeToStringArray(svType: DWORD): TStringDynArray; overload;
function ServerTypeToStrings(const svType: DWord; const Separator: string = ', '): string; overload;

function NetWkstaGetInfo(const servername: PWChar; const level: DWord; const bufptr: Pointer): NET_API_STATUS; stdcall;
function NetServerGetInfo(const servername: PWChar; level: DWORD; bufptr: Pointer): NET_API_STATUS; stdcall;
function NetApiBufferFree(Buffer: Pointer): NET_API_STATUS; stdcall;
function SendARP(const DestIP, SrcIP: IPAddr; pMacAddr: PULONG; var PhyAddrLen: ULONG): DWORD; stdcall;
function NetShareEnum(servername: LMSTR; level: DWORD; var bufptr: LPBYTE; prefmaxlen: DWORD; entriesread,
  totalentries, resume_handle: LPDWORD): DWORD; stdcall;

implementation

const
  netapi32lib       = 'netapi32.dll';
  iphlpapilib       = 'iphlpapi.dll';

function NetWkstaGetInfo; external netapi32lib name 'NetWkstaGetInfo';
function NetServerGetInfo; external netapi32lib name 'NetServerGetInfo';
function NetApiBufferFree; external netapi32lib name 'NetApiBufferFree';
function NetShareEnum; external netapi32lib name 'NetShareEnum';
function SendARP; external iphlpapilib name 'SendARP';

function GetRemoteOS(const Computer: WideString; var Version: string): DWORD;
var
  res               : DWORD;
  s                 : string;
  si                : Pointer;
  Major             : DWORD;
  Minor             : DWORD;
begin
  si := nil;
  s := '';

  res := NetServerGetInfo(PWideChar(Computer), 101, @si);
  if res = NERR_Success then
  begin
    Major := PSERVER_INFO_101(si)^.sv101_version_major;
    Minor := PSERVER_INFO_101(si)^.sv101_version_minor;
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
    end;
  end;
  Version := s;
  NetApiBufferFree(si);
  result := res;
end;

function GetServerComment(const Computer: WideString; var comment: string): DWORD;
var
  res               : DWORD;
  si                : Pointer;
resourcestring
  rsUnknown         = 'Operating system unknown';
begin
  si := nil;
  res := NetServerGetInfo(PWideChar(Computer), 101, @si);
  if res = NERR_Success then
  begin
    comment := PSERVER_INFO_101(si)^.sv101_comment;
  end;
  NetApiBufferFree(si);
  result := res;
end;

function GetDomainName(const Computername: string): string;
var
  err               : Integer;
  buf               : pointer;
  fDomainName       : string;
  wServerName       : WideString;
begin
  buf := nil;
  wServerName := ComputerName;
  err := NetServerGetInfo(PWideChar(wServerName), 503, @buf);
  if err = 0 then
  try
    fDomainName := PSERVER_INFO_503(buf)^.sv503_domain;
  finally
    NetAPIBufferFree(buf)
  end;
  result := fDomainName;
end;

function GetServerType(const Computer: WideString; var SV_Type: DWORD): DWORD;
var
  res               : DWORD;
  si                : Pointer;
resourcestring
  rsUnknown         = 'Operating system unknown';
begin
  si := nil;
  res := NetServerGetInfo(PWideChar(Computer), 101, @si);
  if res = NERR_Success then
  begin
    SV_Type := PSERVER_INFO_101(si)^.sv101_type;
  end;
  NetApiBufferFree(si);
  result := res;
end;

//function ServerTypeToStringArray(svType: DWORD): TStringDynArray; overload;
//const
//  cStrings          : array[0..30] of string = (
//    'LAN Manager workstation',
//    'LAN Manager server',
//    'SQL Server',
//    'Primary domain controller',
//    'Backup domain controller',
//    'Timesource service',
//    'Apple File Protocol server',
//    'Novell server',
//    'LAN Manager 2.x domain member',
//    'Server sharing print queue',
//    'dial-in service',
//    'Xenix server',
//    '',
//    '',
//    'File and Print for NetWare',
//    '',
//    'can run the browser service',
//    'browser service',
//    'browser service as backup',
//    'domain master browser',
//    '',
//    '',
//    'Windows95 and above',
//    'Root of a DFS tree',
//    'NT Cluster',
//    'Terminal Server(Hydra)',
//    'NT Cluster Virtual Server Name',
//    'IBM DSS',
//    '',
//    '',
//    'Primary domain'
//    );
//var
//  I, J              : Integer;
//begin
//  J := 0;
//  SetLength(Result, 31);
//  for I := 0 to 30 do
//    if Odd(svType shr I) then
//    begin
//      Result[J] := cStrings[I];
//      Inc(J);
//    end;
//  SetLength(Result, J);
//end;

function ServerTypeToStrings(const svType: DWord; const Separator: string = ', '): string; overload;
const
  cStrings          : array[0..30] of string = (
    'LAN Manager workstation',
    'LAN Manager server',
    'SQL Server',
    'Primary domain controller',
    'Backup domain controller',
    'Timesource service',
    'Apple File Protocol server',
    'Novell server',
    'LAN Manager 2.x domain member',
    'Server sharing print queue',
    'dial-in service',
    'Xenix server',
    '',
    '',
    'File and Print for NetWare',
    '',
    'can run the browser service',
    'browser service',
    'browser service as backup',
    'domain master browser',
    '',
    '',
    'Windows95 and above',
    'Root of a DFS tree',
    'NT Cluster',
    'Terminal Server(Hydra)',
    'NT Cluster Virtual Server Name',
    'IBM DSS',
    '',
    '',
    'Primary domain'
    );
var
  i                 : Integer;
begin
  Result := '';
  for i := 0 to 30 do
    if Odd(svType shr i) then
      Result := Result + cStrings[i] + Separator;
  SetLength(Result, Length(Result) - Length(Separator));
end;

function ToIP(I1, I2, I3, I4: Integer): Cardinal;

  function Check(Value: Integer): Byte;
  begin
    if (Value >= 0) and (Value <= 255) then
      Result := Value
    else
      exit;
  end;

begin
  Result := Check(I1) shl 24 or Check(I2) shl 16 or Check(I3) shl 8 or Check(I4);
end;

function IPToStr(Value: Cardinal): string;
begin
  Result := Format('%d.%d.%d.%d', [Value shr 24, Value shr 16 and $FF, Value shr 8 and $FF, Value and $FF]);
end;

function IPAddrToName(IPAddr: string): string;
var
  SockAddrIn        : TSockAddrIn;
  HostEnt           : PHostEnt;
  WSAData           : TWSAData;
begin
  WSAStartup($101, WSAData);
  SockAddrIn.sin_addr.s_addr := inet_addr(PChar(IPAddr));
  HostEnt := gethostbyaddr(@SockAddrIn.sin_addr.S_addr, 4, AF_INET);
  if HostEnt <> nil then
    Result := string(Hostent^.h_name)
  else
    Result := '';
end;

function IPToMAC(IP: string): string;
var
  DestIP, SrcIP     : Cardinal;
  pMacAddr          : PULong;
  AddrLen           : ULong;
  MacAddr           : array[0..5] of byte;
  p                 : PByte;
  i                 : integer;
begin
  result := '';
  SrcIp := 0;
  DestIP := inet_addr(PChar(IP));
  pMacAddr := @MacAddr[0];
  AddrLen := SizeOf(MacAddr);
  SendARP(DestIP, SrcIP, pMacAddr, AddrLen);
  p := PByte(pMacAddr);
  if Assigned(p) and (AddrLen > 0) then
    for i := 0 to AddrLen - 1 do
    begin
      result := result + IntToHex(p^, 2) + '-';
      Inc(p);
    end;
  SetLength(result, Length(result) - 1);
end;

type
  TShareInfo0Array = array of _SHARE_INFO_0;

function ListSharedFolders(const ServerName: PWideChar): TStringDynArray;
var
  aShareBuffer      : PSHARE_INFO_0;
  aWorkBuffer       : TShareInfo0Array;
  dwEntriesRead     : Cardinal;
  i                 : integer;
  err               : DWORD;
begin
  aWorkBuffer := nil;
  aShareBuffer := nil;
  err := NetShareEnum(ServerName, 0, PByte(aShareBuffer), MAX_PREFERRED_LENGTH, @dwEntriesRead, @dwEntriesRead,
    nil);
  if err = 0 then
  begin
    aWorkBuffer := TShareInfo0Array(aShareBuffer);
    setlength(result, dwEntriesRead);
    for i := 0 to dwEntriesRead - 1 do
    begin
      result[i] := aWorkBuffer[i].shi0_netname;
    end;
    //NetAPIBufferFree(aShareBuffer);
  end;
end;

end.

