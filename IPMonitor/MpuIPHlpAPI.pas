unit MpuIPHlpAPI;

interface

uses
  windows;

const
  ANY_SIZE = 1;

const
  MAX_ADAPTER_DESCRIPTION_LENGTH = 128;
  MAX_ADAPTER_NAME_LENGTH = 256;
  MAX_ADAPTER_ADDRESS_LENGTH = 8;

type
  PMIB_TCPROW = ^MIB_TCPROW;
  _MIB_TCPROW = packed record
    dwState: DWORD;
    dwLocalAddr: DWORD;
    dwLocalPort: DWORD;
    dwRemoteAddr: DWORD;
    dwRemotePort: DWORD;
  end;
  MIB_TCPROW = _MIB_TCPROW;
  TMibTcpRow = MIB_TCPROW;
  PMibTcpRow = PMIB_TCPROW;

  PMIB_TCPTABLE = ^MIB_TCPTABLE;
  _MIB_TCPTABLE = packed record
    dwNumEntries: DWORD;
    table: array[0..ANY_SIZE - 1] of MIB_TCPROW;
  end;
  MIB_TCPTABLE = _MIB_TCPTABLE;
  TMibTcpTable = MIB_TCPTABLE;
  PMibTcpTable = PMIB_TCPTABLE;

  PMIB_UDPROW = ^MIB_UDPROW;
  _MIB_UDPROW = packed record
    dwLocalAddr: DWORD;
    dwLocalPort: DWORD;
  end;
  MIB_UDPROW = _MIB_UDPROW;
  TMibUdpRow = MIB_UDPROW;
  PMibUdpRow = PMIB_UDPROW;

  PMIB_UDPTABLE = ^MIB_UDPTABLE;
  _MIB_UDPTABLE = packed record
    dwNumEntries: DWORD;
    table: array[0..ANY_SIZE - 1] of MIB_UDPROW;
  end;
  MIB_UDPTABLE = _MIB_UDPTABLE;
  TMibUdpTable = MIB_UDPTABLE;
  PMibUdpTable = PMIB_UDPTABLE;

type
  PIP_ADDRESS_STRING = ^IP_ADDRESS_STRING;
  IP_ADDRESS_STRING =
    packed record
    acString: array[1..16] of Char;
  end;

  PIP_MASK_STRING = ^PIP_MASK_STRING;
  IP_MASK_STRING = IP_ADDRESS_STRING;

  PIP_ADDR_STRING = ^IP_ADDR_STRING;
  IP_ADDR_STRING =
    packed record
    Next: PIP_ADDR_STRING;
    IpAddress: IP_ADDRESS_STRING;
    IpMask: IP_MASK_STRING;
    Context: DWORD;
  end;

  time_t = int64;

  PIP_ADAPTER_INFO = ^IP_ADAPTER_INFO;
  IP_ADAPTER_INFO =
    packed record
    Next: PIP_ADAPTER_INFO;
    ComboIndex: DWORD;
    AdapterName: array[1..MAX_ADAPTER_NAME_LENGTH + 4] of Char;
    Description: array[1..MAX_ADAPTER_DESCRIPTION_LENGTH + 4] of Char;
    AddressLength: UINT;
    Address: array[1..MAX_ADAPTER_ADDRESS_LENGTH] of Byte;
    Index: DWORD;
    dwType: UINT;
    DhcpEnabled: UINT;
    CurrentIpAddress: PIP_ADDR_STRING;
    IpAddressList: IP_ADDR_STRING;
    GatewayList: IP_ADDR_STRING;
    DhcpServer: IP_ADDR_STRING;
    HaveWins: Boolean;
    PrimaryWinsServer: IP_ADDR_STRING;
    SecondaryWinsServer: IP_ADDR_STRING;
    LeaseObtained: time_t;
    LeaseExpires: time_t;
  end;

  PIP_PER_ADAPTER_INFO = ^IP_PER_ADAPTER_INFO;
  IP_PER_ADAPTER_INFO = packed record
    AutoConfigEnabled: UINT;
    AutoConfigActive: UINT;
    CurrentDnsServer: PIP_ADDR_STRING;
    DnsServerList: IP_ADDR_STRING;
  end;

function GetTcpTable(pTcpTable: PMIB_TCPTABLE; var pdwSize: DWORD; bOrder:
  BOOL): DWORD; stdcall;
function GetUdpTable(pUdpTable: PMIB_UDPTABLE; var pdwSize: DWORD; bOrder:
  BOOL): DWORD; stdcall;
function GetAdaptersInfo(const pAdapterInfo: PIP_ADAPTER_INFO; const pOutBufLen:
  PULONG): DWORD; stdcall;
function GetPerAdapterInfo(const pIfIndex: ULONG; const pAdapterInfo:
  PIP_PER_ADAPTER_INFO; const pOutBufLen: PULONG): DWORD; stdcall;

implementation

const
  iphlpapilib = 'iphlpapi.dll';

function GetTcpTable; external iphlpapilib name 'GetTcpTable';
function GetUdpTable; external iphlpapilib name 'GetUdpTable';
function GetAdaptersInfo; external iphlpapilib name 'GetAdaptersInfo';
function GetPerAdapterInfo; external iphlpapilib name 'GetPerAdapterInfo';

end.

