{$A+,B-,D+,E-,F-,G+,H+,I+,J-,K-,L+,M-,N+,O+,P+,Q-,R-,S-,T-,U-,V+,W-,X+,Y+,Z1}
{$MINSTACKSIZE $00004000}
{$MAXSTACKSIZE $00100000}
{$IMAGEBASE $00400000}
{$APPTYPE GUI}

{.$DEFINE DEBUGGING}
{$IFDEF DEBUGGING}
{$ASSERTIONS on}
{$ELSE}
{$ASSERTIONS off}
{$ENDIF}

program IPMonitor;

uses
  windows,
  messages{$IFDEF DEBUGGING},
  SysUtils{$ENDIF},
  CommCtrl,
  MpuIPHlpAPI,
  WinSock,
  WinInet,
  TimerQueue;

{$R ./res/resource.res}
{$INCLUDE SysUtils.inc}

const

  IDC_BTNABOUT = 101;
  IDC_LV = 102;

  FontName = 'Tahoma';
  FontSize = -18;

const

  APPNAME = 'IP Monitor';
  VER = '1.0';
  INFO_TEXT = APPNAME + ' ' + VER + #13#10 +
    'Copyright © Your Name' + #13#10#13#10 +
    'https://github.com';

type
  Cols = array[0..3] of string;

var
  LVColums: Cols = ('local Address:Port', 'remote Adress:Port', 'Protocol',
    'Status');

type
  TIPTCPInfo = record
    Protocol: string[3];
    localIP: DWORD;
    localPort: DWORD;
    remoteIP: DWORD;
    remotePort: DWORD;
    Status: DWORD;
  end;

type
  TIPUDPInfo = record
    Protocol: string[3];
    localIP: DWORD;
    localPort: DWORD;
    remoteIP: DWORD;
    remotePort: DWORD;
    Status: DWORD;
  end;

type
  IPTCPInfo = array of TIPTCPInfo;
  IPUDPInfo = array of TIPUDPInfo;

var
  hApp: Cardinal;
  hTimerQTimer: THandle;

  whitebrush: HBRUSH = 0;

  WhiteLB: TLogBrush =
  (
    lbStyle: BS_SOLID;
    lbColor: $00FFFFFF;
    lbHatch: 0
    );

{*******************************************************************************
  Converts TCP status to string constant

*******************************************************************************}

function TCPStateToStr(status: integer): string;
begin
  status := status - 1;
  case status of
    0: result := 'closed';
    1: result := 'listen';
    2: result := 'SYN_Sent';
    3: result := 'SYN_Rcvd';
    4: result := 'established';
    5: result := 'Fin wait 1';
    6: result := 'Fin wait 2';
    7: result := 'Close wait';
    8: result := 'closing';
    9: result := 'last Ack.';
    10: result := 'time wait';
    11: result := 'delete TCB';
    98: result := '-';
  end;
end;

{*******************************************************************************
   Tries to find a description for a specific port
   Portions Copyright by Salvatore Meschini (http://salvatoremeschini.cjb.net)
*******************************************************************************}

function PortDescription(Port: DWORD): string;
var
  i: integer;
type
  TWKP = record
    Port: DWORD;
    Service: string[50];
  end;

const
  WellKnownPorts: array[1..61] of TWKP
  = ((Port: 1; Service: 'TCP Port Service Multiplexer'),
    (Port: 7; Service: 'ECHO'),
    (Port: 9; Service: 'Discard'),
    (Port: 13; Service: 'DayTime'),
    (Port: 17; Service: 'QOTD - Quote Of The Day'),
    (Port: 18; Service: 'MSP - Message Send Protocol'),
    (Port: 19; Service: 'CharGen - Character Generator'),
    (Port: 20; Service: 'FTPDATA - File Transfer Protocol'),
    (Port: 21; Service: 'FTP - File Transfer Control Protocol'),
    (Port: 22; Service: 'SSH Remote Login Protocol'),
    (Port: 23; Service: 'TELNET'),
    (Port: 25; Service: 'SMTP - Simple Mail Transfer Protocol '),
    (Port: 37; Service: 'TIME'),
    (Port: 38; Service: 'RAP - Route Access Protocol'),
    (Port: 39; Service: 'RLP - Resource Location Protocol'),
    (Port: 42; Service: 'NAMESERVER - Host Name Server'),
    (Port: 53; Service: 'DNS - Domain Name Server'),
    (Port: 66; Service: 'Oracle SQL*NET'),
    (Port: 67; Service: 'BOOTP Server'),
    (Port: 68; Service: 'BOOTP Client'),
    (Port: 69; Service: 'Trivial FTP'),
    (Port: 70; Service: 'GOPHER'),
    (Port: 79; Service: 'FINGER'),
    (Port: 80; Service: 'HTTP - Hyper Text Transfer Protocol'),
    (Port: 88; Service: 'KERBEROS'),
    (Port: 101; Service: 'NIC Host Name Server'),
    (Port: 109; Service: 'POP2 - Post Office Protocol 2'),
    (Port: 110; Service: 'POP3 - Post Office Protocol 3'),
    (Port: 113; Service: 'IDENT - Authentication Service'),
    (Port: 115; Service: 'SFTP - Simple File Transfer Protocol'),
    (Port: 119; Service: 'Network News Transfer Protocol (NNTP)'),
    (Port: 123; Service: 'Network Time Protocol (NTP)'),
    (Port: 135; Service: 'Location Service (RPC) - EPMAP'),
    (Port: 137; Service: 'NETBIOS Name Service'),
    (Port: 138; Service: 'NETBIOS Datagram Service'),
    (Port: 139; Service: 'NETBIOS Session Service'),
    (Port: 161; Service: 'SNMP - Simple Network Management Protocol'),
    (Port: 194; Service: 'IRC - Internet Relay Chat Protocol'),
    (Port: 213; Service: 'IPX'),
    (Port: 443; Service: 'HTTPS - Hyper Text Transfer Protocol Secure'),
    (Port: 445; Service: 'Microsoft-DS'),
    (Port: 500; Service: 'Isakmp'),
    (Port: 523; Service: 'IBM-DB2'),
    (Port: 524; Service: 'NCP'),
    (Port: 525; Service: 'Timeserver'),
    (Port: 1433; Service: 'Microsoft SQL Server'),
    (Port: 1434; Service: 'Microsoft SQL Monitor'),
    (Port: 1512; Service: 'WINS - Windows Internet Name Service'),
    (Port: 1801; Service: 'Microsoft Message Queue'),
    (Port: 1863; Service: 'MSNP'),
    (Port: 2234; Service: 'Directplay'),
    (Port: 3389; Service: 'Microsoft Term Server'),
    (Port: 5000; Service: 'Universal Plug & Play'),
    (Port: 5190; Service: 'ICQ Messenger'),
    (Port: 42424; Service: '.NET State Server'),
    (Port: 8787; Service: 'Back Orifice 2000'),
    (Port: 31337; Service: 'Back Orifice 2000 Russian'),
    (Port: 31338; Service: 'Back Orifice'),
    (Port: 54283; Service: 'Back Orifice 2000'),
    (Port: 54320; Service: 'Back Orifice 2000'),
    (Port: 54321; Service: 'Back Orifice 2000')
    );
begin
  Result := IntToStr(Port);
  for i := Low(WellKnownPorts) to High(WellKnownPorts) do
  begin
    if WellKnownPorts[i].Port = Port then
    begin
      Result := WellKnownPorts[i].Service;
      Break;
    end;
  end;
end;

{*******************************************************************************
  Gets the local computer name

*******************************************************************************}

function ComputerName: string;
var
  Size: DWORD;
begin
  Size := MAX_COMPUTERNAME_LENGTH + 1;
  SetLength(Result, Size);
  if GetComputerName(PChar(Result), Size) then
    SetLength(Result, Size)
  else
    Result := '';
end;

{*******************************************************************************
  Assembles the IP and port description

*******************************************************************************}

function GetName(Addr, Port: DWORD; Local: Boolean): string;
var
  MyAddress: in_addr;
  ServEnt: PServEnt;
  HostEnt: PHostEnt;
begin
  MyAddress.S_addr := Addr;
  result := inet_ntoa(MyAddress);
  if Local or (Addr = 0) then
  begin
    ServEnt := getservbyport(Port, nil);
    if ServEnt <> nil then
      Result := ComputerName + ':' + ServEnt^.s_name + '(' + ServEnt^.s_proto +
        ')'
    else
      Result := ComputerName + ':' + PortDescription(htons(Port));
  end
  else
  begin
    HostEnt := gethostbyaddr(PChar(@Addr), SizeOf(DWORD), AF_INET);
    if HostEnt <> nil then
      Result := HostEnt^.h_name + ':' + IntToStr(htons(word(Port)))
    else
      Result := Result + ':' + PortDescription(htons(word(Port)));
  end;
end;

{*******************************************************************************
  Makes the list-view columns

*******************************************************************************}

procedure MakeLVColumns(hLV: THandle; Columns: Cols);
var
  lvc: TLVColumn;
  i: Cardinal;
begin
  for i := length(Columns) - 1 downto 0 do
  begin
    lvc.mask := LVCF_TEXT or LVCF_WIDTH;
    lvc.pszText := Pointer(Columns[i]);
    lvc.cx := 200;
    if i = 2 then
      lvc.cx := 75;
    if i = 3 then
      lvc.cx := 75;
    ListView_InsertColumn(hLV, 0, lvc);
  end;
end;

{*******************************************************************************
  Fills the list-view with the IPTCPInfo and IPUDPINFO arrays

*******************************************************************************}

procedure FillLV(hLV: THandle; TCPItems: IPTCPInfo; UDPItems: IPUDPInfo);
var
  lvi: TLVItem;
  SelRow: Integer;
  i: Cardinal;
  s: string;
  ItemsCnt: Integer;
begin
  // don't update the window
  LockWindowUpdate(hLV);
  // save current selection
  SelRow := SendMessage(hLV, LVM_GETNEXTITEM, -1, LVNI_SELECTED);
  // clear the list-view
  SendMessage(hLV, LVM_DELETEALLITEMS, 0, 0);
  lvi.mask := LVIF_TEXT;
  // fill the list-view (UDP)
  for i := 0 to length(UDPItems) - 1 do
  begin
    s := GetName(UDPItems[i].localIP, UDPItems[i].localPort, True);
    lvi.iItem := i;
    lvi.iSubItem := 0;
    lvi.pszText := pointer(s);
    ListView_InsertItem(hLV, lvi);
    s := '*:*';
    lvi.iItem := i;
    lvi.iSubItem := 1;
    lvi.pszText := pointer(s);
    ListView_SetItem(hLv, lvi);
    s := UDPItems[i].Protocol;
    lvi.iItem := i;
    lvi.iSubItem := 2;
    lvi.pszText := pointer(s);
    ListView_SetItem(hLv, lvi);
    s := '-';
    lvi.iItem := i;
    lvi.iSubItem := 3;
    lvi.pszText := pointer(s);
    ListView_SetItem(hLv, lvi);
  end;
  // fill the list-view (TCP)
  for i := 0 to length(TCPItems) - 1 do
  begin
    s := GetName(TCPItems[i].localIP, TCPItems[i].localPort, True);
    lvi.iItem := i;
    lvi.iSubItem := 0;
    lvi.pszText := pointer(s);
    ListView_InsertItem(hLV, lvi);
    s := GetName(TCPItems[i].remoteIP, TCPItems[i].remotePort, False);
    lvi.iItem := i;
    lvi.iSubItem := 1;
    lvi.pszText := pointer(s);
    ListView_SetItem(hLv, lvi);
    s := TCPItems[i].Protocol;
    lvi.iItem := i;
    lvi.iSubItem := 2;
    lvi.pszText := pointer(s);
    ListView_SetItem(hLv, lvi);
    s := TCPStateToStr(TCPItems[i].Status);
    lvi.iItem := i;
    lvi.iSubItem := 3;
    lvi.pszText := pointer(s);
    ListView_SetItem(hLv, lvi);
  end;
  // release lock
  LockWindowUpdate(0);
  // restore selection
  ItemsCnt := SendMessage(hLV, LVM_GETITEMCOUNT, 0, 0);
  if ItemsCnt >= SelRow then
  begin
    lvi.stateMask := LVNI_SELECTED;
    lvi.state := LVNI_SELECTED;
    SendMessage(hLV, LVM_SETITEMSTATE, SelRow, Integer(@lvi));
  end;
end;

{*******************************************************************************
  Gets the details for TCP connections

*******************************************************************************}

function GetIPTCPInfos: IPTCPInfo;
var
  Error: DWORD;
  TCPTable: PMibTcpTable;
  NumEntriesTCP: DWORD;
  dwSize: DWORD;
  i: Integer;
begin
  Setlength(result, 0);
  dwSize := 0;
  // how much memory do we need?
  Error := GetTcpTable(nil, dwSize, False);
  if Error <> ERROR_INSUFFICIENT_BUFFER then
    Exit;
  // allocvate memory
  GetMem(TCPTable, dwSize);
  try
    // call GetTCPTable again to obtain the information
    if GetTCPTable(TcpTable, dwSize, TRUE) = NO_ERROR then
    begin
      if TCPTable <> nil then // it worked :)
      begin
        NumEntriesTCP := TCPTable.dwNumEntries;
        SetLength(result, NumEntriesTCP);
        // iterate through entries
        for i := 0 to NumEntriesTCP - 1 do
        begin
          result[i].Protocol := 'TCP';
          result[i].localIP := TCPTable^.table[i].dwLocalAddr;
          result[i].localPort := TCPTable^.table[i].dwlocalPort;
          result[i].remoteIP := TCPTable^.table[i].dwRemoteAddr;
          if TCPTable^.table[i].dwRemoteAddr = 0 then
            TCPTable^.table[i].dwRemotePort := 0;
          result[i].remotePort := TCPTable^.table[i].dwRemotePort;
          result[i].Status := TCPTable^.table[i].dwState;
        end;
      end;
    end;
  finally
    FreeMem(TCPTable, dwSize);
  end;
end;

{*******************************************************************************
  Gets the details for the UDP connections

*******************************************************************************}

function GetIPUDPInfos: IPUDPInfo;
var
  Error: DWORD;
  UDPTable: PMibUdptable;
  NumEntriesUDP: DWORD;
  dwSize: DWORD;
  i: Integer;
begin
  setlength(result, 0);
  dwSize := 0;
  Error := GetUdpTable(nil, dwSize, False);
  if Error <> ERROR_INSUFFICIENT_BUFFER then
    exit;
  GetMem(UDPTable, dwSize);
  try
    if GetUdpTable(UDPTable, dwSize, TRUE) = NO_ERROR then
    begin
      if UDPTable <> nil then
      begin
        NumEntriesUDP := UDPTable.dwNumEntries;
        SetLength(result, NumEntriesUDP);
        for i := 0 to NumEntriesUDP - 1 do
        begin
          result[i].Protocol := 'UDP';
          result[i].localIP := UDPTable^.table[i].dwLocalAddr;
          result[i].localPort := UDPTable^.table[i].dwLocalPort;
          result[i].remoteIP := 0;
          result[i].remotePort := 0;
          result[i].Status := 99;
        end;
      end;
    end;
  finally
    FreeMem(UDPTable, dwSize);
  end;
end;

{*******************************************************************************
  TimerQueue function
  
*******************************************************************************}

procedure TimerQueueThread(Context: Pointer; TimeOut: Boolean); stdcall;
begin
  FillLV(GetDlgItem(hApp, IDC_LV), GetIPTCPInfos, GetIPUDPInfos);
end;

function dlgfunc(hDlg: hWnd; uMsg: dword; wParam: wParam; lParam: lParam): bool;
  stdcall;
var
  MyFont: HFONT;
  s: string;
begin
  result := true;
  case uMsg of
    WM_INITDIALOG:
      begin
        hApp := hDlg;
        MyFont := CreateFont(FontSize, 0, 0, 0, 900, 0, 0, 0, ANSI_CHARSET,
          OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
          DEFAULT_PITCH, FontName);
        if MyFont <> 0 then
          SendDlgItemMessage(hDlg, 999, WM_SETFONT, Integer(MyFont),
            Integer(true));
        s := APPNAME;
        SetWindowText(hDlg, pointer(s));
        SetDlgItemText(hDlg, 999, pointer(s));
        MakeLVColumns(GetDlgItem(hDlg, IDC_LV), LVColums);
        SendMessage(GetDlgItem(hDlg, IDC_LV), LVM_SETEXTENDEDLISTVIEWSTYLE,
          LVS_EX_FULLROWSELECT, LVS_EX_FULLROWSELECT);
        CreateTimerQueueTimer(hTimerQTimer, 0, @TimerQueueThread, nil, 0,
          2000, 0);
      end;
    WM_CTLCOLORSTATIC:
      begin
        case GetDlgCtrlId(lParam) of
          999: { color the banner white }
            begin
              whitebrush := CreateBrushIndirect(WhiteLB);
              SetBkColor(wParam, WhiteLB.lbColor);
              result := BOOL(whitebrush);
            end;
        end;
      end;
    WM_LBUTTONDOWN:
      begin
        SetCursor(LoadCursor(0, IDC_SIZEALL));
        SendMessage(hDlg, WM_NCLBUTTONDOWN, HTCAPTION, lParam);
      end;
    WM_SIZE:
      begin
        MoveWindow(GetDlgItem(hDlg, 999), 0, 0, loword(lParam), 75, TRUE);
        s := APPNAME;
        SetDlgItemText(hDlg, 999, pointer(s));
        SetWindowPos(GetDlgItem(hDlg, 101), GetDlgItem(hDlg, 999), loword(lParam)
          - 47, 7, 40, 22, 0);
        MoveWindow(GetDlgItem(hDlg, IDC_LV), 0,
          78, loword(lParam), hiword(lParam) - 78, TRUE);
      end;
    WM_CLOSE:
      begin
        DeleteTimerQueueTimer(0, hTimerQTimer, 0);
        EndDialog(hDlg, 0);
      end;
    WM_COMMAND:
      begin
      { accel for closing the dialog with ESC }
        if wParam = ID_CANCEL then
          SendMessage(hDlg, WM_CLOSE, 0, 0);
      { button and menu clicks }
        if hiword(wParam) = BN_CLICKED then
        begin
          case LoWord(wParam) of
            IDC_BTNABOUT: MessageBox(hDlg, INFO_TEXT, APPNAME,
                MB_ICONINFORMATION);
          end;
        end;
      end
  else
    result := false;
  end;
end;

begin
  InitCommonControls;
  DialogBox(hInstance, MAKEINTRESOURCE(100), 0, @dlgfunc);
end.

