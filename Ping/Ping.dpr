
 (* ToDo
  * Users can choose the number of threads themselves (within reasonable limits).
  * Export to a CSV file
 *)

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

program Ping;

uses
  windows,
  messages,
  CommCtrl,
  WinSock,
  ShellAPI,
  TlHelp32,
  MpuTools in 'units\common\MpuTools.pas',
  globals in 'units\common\globals.pas',
  retPing in 'units\ping\retPing.pas',
  IpHlpApi in 'units\ping\IpHlpApi.pas',
  IpTypes in 'units\ping\IpTypes.pas',
  IpExport in 'units\ping\IpExport.pas',
  IpIfConst in 'units\ping\IpIfConst.pas',
  IpRtrMib in 'units\ping\IpRtrMib.pas',
  MpuNTLan in 'units\ntlan\MpuNTLan.pas',
  CommCtrl_Fragment in 'units\common\CommCtrl_Fragment.pas';

{$R '.\res\resource.res'}

const
  IDC_STC_BANNER    = 101;
  IDC_STC_DEVIDER   = 102;
  IDC_BTN_ABOUT     = 103;
  IDC_LV            = 104;
  IDC_SB            = 105;
  IDC_IP_FROM       = 106;
  IDC_IP_TO         = 107;
  IDC_BTN_START     = 108;
  IDC_BTN_CANCEL    = 109;
  IDC_PB            = 110;
  IDC_CHK_VERBOSE   = 111;

  FONTNAME          = 'Tahoma';
  FONTSIZE          = -18;

type
  TStringArray = array of string;

type
  TThreadParams = packed record
    Range: TStringArray;
  end;
  PThreadParams = ^TThreadParams;

  TOpenThreadParams = packed record
    Computer: string[255];
  end;
  POpenThreadParams = ^TOpenThreadParams;

const
  MAXTHREADS        = 255;

var
  hApp              : THandle;
  Terminate         : Boolean = False;
  Img               : THandle;
  Range             : TStringArray;
  SubRange          : array of TStringArray;
  ThreadArray       : array of THandle;
  cntPings          : Integer;
  cntMachines       : Integer;
  Secs              : Cardinal;
  cs                : RTL_CRITICAL_SECTION;
  SortOrder         : byte = 1;
  hSortImg          : THandle;
  LastCol           : integer = 0;

////////////////////////////////////////////////////////////////////////////////

function CountThreads(ProcID: DWORD): Integer;
var
  hSnapShot         : THandle;
  pe32              : TProcessEntry32;
begin
  result := 0;

  hSnapShot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, ProcID);
  if hSnapShot <> INVALID_HANDLE_VALUE then
  begin
    ZeroMemory(@pe32, sizeof(TProcessEntry32));
    pe32.dwSize := sizeof(TProcessEntry32);
    Process32First(hSnapShot, pe32);
    if pe32.th32ProcessID = ProcID then
    begin
      result := pe32.cntThreads;
    end
    else
    begin
      repeat
        if pe32.th32ProcessID = ProcID then
        begin
          result := pe32.cntThreads;
          break;
        end;
      until Process32Next(hSnapShot, pe32) = False;
    end;
  end;
end;

function PingThread(p: PThreadParams): Integer;
var
  Range             : TStringArray;
  i                 : Integer;
  time              : Integer;
  Name              : string;
  IP                : string;
  MAC               : string;
  Domain            : string;
  pBuffer           : Pointer;
  WorkGroup         : string;
  SV_Type           : DWORD;
  ServerType        : string;
  Version           : string;
  Comment           : string;
  Shares            : TStringDynArray;
  err               : DWORD;

  lvi               : TLVItem;
  cntItem           : Cardinal;
begin

  pBuffer := nil;
  Name := '';
  IP := '';
  MAC := '';
  Domain := '';
  WorkGroup := '';
  SV_Type := 0;
  ServerType := '';
  Version := '';
  Comment := '';
  Shares := nil;

  ZeroMemory(@lvi, sizeof(TLVITEM));
  lvi.mask := LVIF_TEXT or LVIF_IMAGE;

  Range := PThreadParams(p).Range;
  for i := 0 to length(Range) - 1 do
  begin
    if Terminate then
      break;
    time := PingDW(DNSNameToIp(Range[i]));
    if time <> -1 then
    begin
      if Terminate then
        break;

      if NetWkstaGetInfo(PWideChar(WideString(Range[i])), 100, @pBuffer) = NERR_SUCCESS then
        Name := PWKSTA_INFO_100(pBuffer)^.wki100_computername
      else
        Name := IPAddrToName((Range[i]));

      if Terminate then
        break;

      IP := (Range[i]);
      if (Name <> '.') and (Name <> '') then
        Shares := ListSharedFolders(PWideChar(WideString(Range[i])));
      if length(Shares) > 0 then
        lvi.iImage := 1
      else
        lvi.iImage := 0;

      if IsDlgButtonChecked(hApp, IDC_CHK_VERBOSE) = BST_CHECKED then
      begin
        if Terminate then
          break;

        MAC := IPToMAC(Range[i]);

        if Terminate then
          break;

        Domain := GetDomainName(Name);

        if Terminate then
          break;

        if (Name <> '.') and (Name <> '') then
        begin
          if Terminate then
            break;

          if NetWkstaGetInfo(PWideChar(WideString(Name)), 100, @pBuffer) = NERR_SUCCESS then
            WorkGroup := PWKSTA_INFO_100(pBuffer)^.wki100_langroup;

          if Terminate then
            break;

          GetServerType(Range[i], SV_TYPE);
          ServerType := ServerTypeToStrings(SV_Type);

          if Terminate then
            break;

          err := GetRemoteOS(Range[i], Version);
          if err <> 0 then
            Version := SysErrorMessage(err);

          if Terminate then
            break;

          err := GetServerComment(Range[i], Comment);
          if err <> 0 then
            Comment := SysErrorMessage(err);
        end;
      end;

      EnterCriticalSection(cs);

      cntItem := SendDlgItemMessage(hApp, IDC_LV, LVM_GETITEMCOUNT, 0, 0);
      lvi.pszText := PChar(Name);
      lvi.iItem := cntItem;
      lvi.iSubItem := 0;
      SendDlgItemMessage(hApp, IDC_LV, LVM_INSERTITEM, 0, Integer(@lvi));

      lvi.pszText := PChar(IP);
      lvi.iSubItem := 1;
      SendDlgItemMessage(hApp, IDC_LV, LVM_SETITEM, 0, Integer(@lvi));

      lvi.pszText := PChar(MAC);
      lvi.iSubItem := 2;
      SendDlgItemMessage(hApp, IDC_LV, LVM_SETITEM, 0, Integer(@lvi));

      lvi.pszText := PChar(Domain);
      lvi.iSubItem := 3;
      SendDlgItemMessage(hApp, IDC_LV, LVM_SETITEM, 0, Integer(@lvi));

      lvi.pszText := PChar(WorkGroup);
      lvi.iSubItem := 4;
      SendDlgItemMessage(hApp, IDC_LV, LVM_SETITEM, 0, Integer(@lvi));

      lvi.pszText := PChar(ServerType);
      lvi.iSubItem := 5;
      SendDlgItemMessage(hApp, IDC_LV, LVM_SETITEM, 0, Integer(@lvi));

      lvi.pszText := PChar(Version);
      lvi.iSubItem := 6;
      SendDlgItemMessage(hApp, IDC_LV, LVM_SETITEM, 0, Integer(@lvi));

      lvi.pszText := PChar(Comment);
      lvi.iSubItem := 7;
      SendDlgItemMessage(hApp, IDC_LV, LVM_SETITEM, 0, Integer(@lvi));

      lvi.pszText := PChar(IntToStr(time));
      lvi.iSubItem := 8;
      SendDlgItemMessage(hApp, IDC_LV, LVM_SETITEM, 0, Integer(@lvi));

      LeaveCriticalSection(cs);
      InterlockedIncrement(cntMachines);
    end;
    InterlockedIncrement(cntPings);
  end;
  // LeaveCriticalSection(cs);
  Dispose(p);
  result := 0;
end;

function OpenThread(p: POpenThreadParams): Integer;
var
  Computer          : string;
  err               : DWORD;
begin
  Computer := POpenThreadParams(p).Computer;
  err := ShellExecute(hApp, 'explore', PChar(Computer), nil, nil, SW_SHOWNORMAL);
  if err < 33 then
    MessageBox(hApp, PChar(SysErrorMessage(GetLastError)), APPNAME, MB_ICONSTOP);
  Dispose(p);
  result := 0;
end;

procedure MakeColumns(hLV: THandle);
var
  lvc               : TLVColumn;
resourcestring
  rsComp            = 'Computername';
  rsIP              = 'IP';
  rsMAC             = 'MAC Adress';
  rsDomain          = 'Domain';
  rsWG              = 'Working group';
  rsType            = 'Servertyp';
  rsOS              = 'Operating system';
  rsComment         = 'Comment';
  rsTime            = 'Time [ms]';
begin
  ZeroMemory(@lvc, sizeof(TLVColumn));
  lvc.mask := LVCF_TEXT or LVCF_WIDTH or LVCF_FMT;
  lvc.pszText := PChar(rsComp);
  lvc.cx := 120;
  SendMessage(hLV, LVM_INSERTCOLUMN, 0, Integer(@lvc));

  lvc.mask := lvc.mask;
  lvc.pszText := PChar(rsIP);
  lvc.cx := 100;
  SendMessage(hLV, LVM_INSERTCOLUMN, 1, Integer(@lvc));

  lvc.pszText := PChar(rsMAC);
  lvc.cx := 110;
  SendMessage(hLV, LVM_INSERTCOLUMN, 2, Integer(@lvc));

  lvc.pszText := PChar(rsDomain);
  lvc.cx := 110;
  SendMessage(hLV, LVM_INSERTCOLUMN, 3, Integer(@lvc));

  lvc.pszText := PChar(rsWG);
  lvc.cx := 110;
  SendMessage(hLV, LVM_INSERTCOLUMN, 4, Integer(@lvc));

  lvc.pszText := PChar(rsType);
  lvc.cx := 110;
  SendMessage(hLV, LVM_INSERTCOLUMN, 5, Integer(@lvc));

  lvc.pszText := PChar(rsOS);
  lvc.cx := 100;
  SendMessage(hLV, LVM_INSERTCOLUMN, 6, Integer(@lvc));

  lvc.pszText := PChar(rsComment);
  lvc.cx := 123;
  SendMessage(hLV, LVM_INSERTCOLUMN, 7, Integer(@lvc));

  lvc.pszText := PChar(rsTime);
  lvc.fmt := LVCFMT_RIGHT;
  lvc.cx := 100;
  SendMessage(hLV, LVM_INSERTCOLUMN, 8, Integer(@lvc));
end;

function CompareFunc(lp1, lp2, SubItem: LPARAM): integer; stdcall;
var
  buf1, buf2        : string;
  ip1, ip2          : Integer;
  a, b              : integer;
begin
  SetLength(buf1, MAX_PATH);
  ZeroMemory(@buf1[1], MAX_PATH);
  SetLength(buf2, MAX_PATH);
  ZeroMemory(@buf2[2], MAX_PATH);
  ListView_GetItemText(GetDlgItem(hApp, IDC_LV), lp1, SubItem, @buf1[1], MAX_PATH);
  ListView_GetItemText(GetDlgItem(hApp, IDC_LV), lp2, SubItem, @buf2[1], MAX_PATH);

  case SubItem of
    1: // IP
      begin
        ip1 := htonl(inet_addr(PChar(buf1)));
        ip2 := htonl(inet_addr(PChar(buf2)));
        if (SortOrder = 1) then
          result := ip2 - ip1
        else
          result := ip1 - ip2;
      end;
    7: // Time
      begin
        if (SortOrder = 1) then
        begin
          b := StrToInt(buf1);
          a := StrToInt(buf2);
        end
        else
        begin
          a := StrToInt(buf1);
          b := StrToInt(buf2);
        end;
        if (a > b) then
          Result := 1
        else if (a < b) then
          Result := -1
        else
          Result := 0;
      end
  else
    begin
      if (SortOrder = 1) then
        Result := lstrcmpi(@buf2[1], @buf1[1])
      else
        Result := lstrcmpi(@buf1[1], @buf2[1]);
    end;
  end;
end;

procedure SortLV(hLV: THandle);
var
  lvi               : TLVItem;
  i                 : Integer;
begin
  lvi.mask := LVIF_PARAM;
  lvi.iSubItem := 0;
  lvi.iItem := 0;
  for i := 0 to SendMessage(hLV, LVM_GETITEMCOUNT, 0, 0) - 1 do
  begin
    lvi.lParam := lvi.iItem;
    SendMessage(hLV, LVM_SETITEM, 0, Integer(@lvi));
    Inc(lvi.iItem);
  end;
end;

const
  fSortBmp          : array[boolean] of integer =
    (HDF_SORTDOWN, HDF_SORTUP);
  BMP_SORTBMP       = 300;
var
  hHeader           : HWND;
  iHeaderVer        : integer = 0;

procedure SetHeader_SortBmp(const hwndHeader: HWND; iIdx: integer);
var
  hi                : THDItem;
  buf               : array[0..MAX_PATH] of char;
begin
  // Determine current header data
  hi.Mask := HDI_FORMAT or HDI_IMAGE or HDI_ORDER or HDI_TEXT or
    HDI_WIDTH;
  hi.pszText := buf;
  hi.cchTextMax := sizeof(buf);
  Header_GetItem(hwndHeader, iIdx, hi);

  // Add sort bitmap
  hi.fmt := hi.fmt or HDF_BITMAP_ON_RIGHT;
  if (iHeaderVer >= 6) then
    hi.fmt := hi.fmt or fSortBmp[SortOrder = 0]
  else
  begin
    hi.fmt := hi.fmt or HDF_IMAGE;
    hi.iImage := SortOrder;
  end;
  Header_SetItem(hwndHeader, iIdx, hi);
end;

procedure SetHeader_RemoveBmp(const hwndHeader: HWND; iIdx: integer);
var
  hi                : THDItem;
  buf               : array[0..MAX_PATH] of char;
begin
  // Retrieve current header data
  hi.Mask := HDI_BITMAP or HDI_FORMAT or HDI_IMAGE or HDI_ORDER or
    HDI_TEXT or HDI_WIDTH;
  hi.pszText := buf;
  hi.cchTextMax := sizeof(buf);
  Header_GetItem(hwndHeader, iIdx, hi);

  // Remove Bitmap flags
  hi.fmt := hi.fmt and not fSortBmp[true] and not fSortBmp[false]
    and not HDF_BITMAP_ON_RIGHT and not HDF_IMAGE;
  Header_SetItem(hwndHeader, iIdx, hi);
end;

function GetItemCaption: string;
var
  lvi               : TLVItem;
  Buffer            : array[0..255] of Char;
begin
  ZeroMemory(@lvi, sizeof(lvi));
  { Which entry is highlighted? }
  lvi.iItem := SendDlgItemMessage(hApp, IDC_LV, LVM_GETNEXTITEM, -1, LVNI_FOCUSED);
  lvi.iSubItem := 0;
  lvi.mask := LVIF_TEXT;
  lvi.pszText := Buffer;
  lvi.cchTextMax := 256;
  { Get Caption }
  SendDlgItemMessage(hApp, IDC_LV, LVM_GETITEM, 0, Integer(@lvi));
  result := string(Buffer);
end;

procedure Start;
begin
  Terminate := False;
  cntPings := 0;
  Secs := 0;
  cntmachines := 0;

  EnableControl(hApp, IDC_BTN_CANCEL, True);
  EnableControl(hApp, IDC_IP_FROM, False);
  EnableControl(hApp, IDC_IP_TO, False);
  EnableControl(hApp, IDC_BTN_START, False);
  SendDlgItemMessage(hApp, IDC_LV, LVM_DELETEALLITEMS, 0, 0);
  SendDlgItemMessage(hApp, IDC_PB, PBM_SETRANGE, 0, MAKELPARAM(0, length(Range)));
  SendDlgItemMessage(hApp, IDC_PB, PBM_SETPOS, 0, 0);
  SendDlgItemMessage(hApp, IDC_SB, SB_SETTEXT, 0, 0);
  SendDlgItemMessage(hApp, IDC_SB, SB_SETTEXT, 1, 0);
end;

procedure Finished;
var
  s                 : string;
resourcestring
  rsFoundMachines   = 'found computer: %d';
  rsTime            = 'Time: %d Seconds';
begin
  KillTimer(hApp, 0);
  EnableControl(hApp, IDC_IP_FROM, True);
  EnableControl(hApp, IDC_IP_TO, True);
  EnableControl(hApp, IDC_BTN_START, True);
  EnableControl(hApp, IDC_BTN_CANCEL, False);
  SendDlgItemMessage(hApp, IDC_PB, PBM_SETPOS, 0, 0);
  s := Format(rsFoundMachines, [SendDlgItemMessage(hApp, IDC_LV, LVM_GETITEMCOUNT, 0, 0)]);
  SendDlgItemMessage(hApp, IDC_SB, SB_SETTEXT, 0, Integer(PChar(s)));
  SendDlgItemMessage(hApp, IDC_SB, SB_SETTEXT, 2, 0);
  SendDlgItemMessage(hApp, IDC_SB, SB_SETTEXT, 3, 0);
  SendDlgItemMessage(hApp, IDC_SB, SB_SETICON, 4, 0);
  SendDlgItemMessage(hApp, IDC_SB, SB_SETTEXT, 4, 0);
end;

function dlgfunc(hDlg: hWnd; uMsg: dword; wParam: wParam; lParam: lParam): bool;
  stdcall;
var
  MyFont            : HFONT;
  s                 : string;
  rec               : TRect;
  PanelWidth        : array[0..4] of integer;
  dwReturn          : DWORD;
  Version           : string;
  Description       : string;
  rect              : TRect;
  pt                : TPoint;
  ip_from           : DWORD;
  ip_to             : DWORD;
  ip1_int           : Cardinal;
  ip2_int           : Cardinal;
  ip_temp           : Cardinal;
  ThreadParams      : PThreadParams;
  i                 : Integer;
  cnt               : Integer;
  ThreadID          : Cardinal;
  len               : Integer;
  OpenParams        : POpenThreadParams;
resourcestring
  rsTime            = 'Time: %d Seconds';
  rsFoundMachines   = 'found computer: %d';
  rsThreads         = 'Threads: %d';
  rsMachinesLeft    = 'remaining addresses: %d';
  rsCancel          = 'Aborted by user. Threads are terminated....';
begin
  result := true;
  case uMsg of
    WM_INITDIALOG:
      begin
        hApp := hDlg;
        // Dialog icon
        if SendMessage(hDlg, WM_SETICON, ICON_SMALL, Integer(LoadIcon(SysInit.HInstance, MAKEINTRESOURCE(1)))) = 0 then
          SendMessage(hDlg, WM_SETICON, ICON_BIG, Integer(LoadIcon(SysInit.HInstance, MAKEINTRESOURCE(1))));
        // Banner font
        MyFont := CreateFont(FONTSIZE, 0, 0, 0, 900, 0, 0, 0, ANSI_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
          DEFAULT_QUALITY, DEFAULT_PITCH, FONTNAME);
        if MyFont <> 0 then
          SendDlgItemMessage(hDlg, IDC_STC_BANNER, WM_SETFONT, Integer(MyFont), Integer(true));
        // Window caption and banner caption
        s := GetCompName + ' - ' + APPNAME;
        SetWindowText(hDlg, pointer(s));
        SetDlgItemText(hDlg, IDC_STC_BANNER, pointer(s));

        //CheckDlgButton(hDlg, IDC_CHK_VERBOSE, BST_CHECKED);

        MakeColumns(GetDlgItem(hDlg, IDC_LV));

        SendMessage(GetDlgItem(hDlg, IDC_IP_FROM), IPM_SETADDRESS, 0, MAKEIPADDRESS(192, 168, 100, 1));
        SendMessage(GetDlgItem(hDlg, IDC_IP_TO), IPM_SETADDRESS, 0, MAKEIPADDRESS(192, 168, 100, 255));

        GetClientRect(hDlg, rec);
        PanelWidth[0] := 165;
        PanelWidth[1] := 300;
        PanelWidth[2] := 490;
        PanelWidth[3] := rec.Right - rec.Left - 260;
        PanelWidth[4] := -1;
        SendDlgItemMessage(hDlg, IDC_SB, SB_SETPARTS, 5, Integer(@PanelWidth));
        SendDlgItemMessage(hDlg, IDC_SB, SB_SETICON, 0, LoadImage(HInstance, MAKEINTRESOURCE(2), IMAGE_ICON, 16, 16,
          0));
        SendDlgItemMessage(hDlg, IDC_SB, SB_SETICON, 1, LoadImage(HInstance, MAKEINTRESOURCE(3), IMAGE_ICON, 16, 16,
          LR_LOADTRANSPARENT));
        SendDlgItemMessage(hDlg, IDC_SB, SB_SETICON, 2, LoadImage(HInstance, MAKEINTRESOURCE(6), IMAGE_ICON, 16, 16,
          LR_LOADTRANSPARENT));
        SendDlgItemMessage(hDlg, IDC_SB, SB_SETICON, 3, LoadImage(HInstance, MAKEINTRESOURCE(4), IMAGE_ICON, 16, 16,
          LR_LOADTRANSPARENT));

        Img := ImageList_Create(16, 16, ILC_COLOR8, 0, 0);
        ImageList_AddIcon(Img, LoadImage(HInstance, MAKEINTRESOURCE(2), IMAGE_ICON, 16, 16, LR_LOADTRANSPARENT));
        ImageList_AddIcon(Img, LoadImage(HInstance, MAKEINTRESOURCE(7), IMAGE_ICON, 16, 16, LR_LOADTRANSPARENT));
        SendDlgItemMessage(hDlg, IDC_LV, LVM_SETIMAGELIST, LVSIL_SMALL, Img);
        ListView_SetExtendedListViewStyle(GetDlgItem(hDlg, IDC_LV), LVS_EX_FULLROWSELECT or LVS_EX_INFOTIP);

        hHeader := ListView_GetHeader(GetDlgItem(hDlg, IDC_LV));
        iHeaderVer := SendMessage(hHeader, CCM_GETVERSION, 0, 0);

        if (iHeaderVer < 6) then
        begin
          hSortImg := ImageList_LoadBitmap(hInstance, MAKEINTRESOURCE(BMP_SORTBMP), 7, 1, $00C0C0C0);
          Header_SetImageList(hHeader, hSortImg);
        end;
      end;
    WM_CTLCOLORSTATIC:
      begin
        case GetDlgCtrlId(lParam) of
          IDC_STC_BANNER: { color the banner white }
            begin
              result := BOOL(GetStockObject(WHITE_BRUSH));
            end;
        else
          Result := False;
        end;
      end;
    { move the window with the left button down }
    WM_LBUTTONDOWN:
      begin
        SetCursor(LoadCursor(0, IDC_SIZEALL));
        SendMessage(hDlg, WM_NCLBUTTONDOWN, HTCAPTION, lParam);
      end;
    WM_SIZE:
      begin
        ShowWindow(GetDlgItem(hDlg, 112), SW_SHOW);
        MoveWindow(GetDlgItem(hDlg, IDC_STC_BANNER), 0, 0, loword(lParam), 75, TRUE);
        s := APPNAME;
        SetDlgItemText(hDlg, IDC_STC_BANNER, pointer(s));
        SetWindowPos(GetDlgItem(hDlg, IDC_BTN_ABOUT), GetDlgItem(hDlg, IDC_STC_BANNER), loword(lParam) - 47, 7, 0, 0,
          SWP_SHOWWINDOW or SWP_NOSIZE);
        GetWindowRect(GetDlgItem(hDlg, IDC_STC_BANNER), rect);
        pt.X := rect.Left;
        pt.Y := rect.Bottom;
        ScreenToClient(hDlg, pt);
        MoveWindow(GetDlgItem(hDlg, IDC_STC_DEVIDER), 0, pt.Y, rect.Right - rect.Left, 2, True);
        SetWindowPos(GetDlgItem(hDlg, IDC_LV), HWND_BOTTOM, 10, 115, loword(lParam) - 20, hiword(lparam) - 170,
          SWP_SHOWWINDOW);
        SetWindowPos(GetDlgItem(hDlg, IDC_BTN_START), HWND_BOTTOM, loword(lParam) - 188, hiword(lParam) - 48, 0, 0,
          SWP_SHOWWINDOW or SWP_NOSIZE);
        SetWindowPos(GetDlgItem(hDlg, IDC_BTN_CANCEL), HWND_BOTTOM, loword(lParam) - 95, hiword(lParam) - 48, 0, 0,
          SWP_SHOWWINDOW or SWP_NOSIZE);
        SetWindowPos(GetDlgItem(hDlg, IDC_PB), HWND_BOTTOM, 10, hiword(lParam) - 45, loword(lParam) - 210, 16,
          SWP_SHOWWINDOW);
        SetWindowPos(GetDlgItem(hDlg, IDC_SB), HWND_BOTTOM, 0, hiword(lparam) - 22, loword(lParam), 22,
          SWP_SHOWWINDOW);
      end;
    WM_CLOSE:
      begin
        Terminate := True;
        for i := 0 to length(ThreadArray) - 1 do
          TerminateThread(ThreadArray[i], 0);
        EndDialog(hDlg, 0);
      end;
    WM_TIMER:
      begin
        Inc(Secs);
        SendDlgItemMessage(hDlg, IDC_PB, PBM_SETPOS, cntPings, 0);
        s := Format(rsFoundMachines, [cntMachines]);
        SendDlgItemMessage(hApp, IDC_SB, SB_SETTEXT, 0, Integer(PChar(s)));
        s := Format(rsTime, [Secs]);
        SendDlgItemMessage(hApp, IDC_SB, SB_SETTEXT, 1, Integer(PChar(s)));
        s := Format(rsMachinesLeft, [length(Range) - cntPings]);
        SendDlgItemMessage(hApp, IDC_SB, SB_SETTEXT, 2, Integer(PChar(s)));
        s := Format(rsThreads, [CountThreads(GetCurrentProcessID)]);
        SendDlgItemMessage(hApp, IDC_SB, SB_SETTEXT, 3, Integer(PChar(s)));
        if (SendDlgItemMessage(hDlg, IDC_PB, PBM_GETPOS, 0, 0) = length(Range)) or
          (CountThreads(GetCurrentProcessID) = 1) then
        begin
          Finished;
        end;
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
            IDC_BTN_ABOUT:
              begin
                dwReturn := GetVersionInfo(Version, Description);
                if dwReturn = 0 then
                begin
                  s := Format(INFO_TEXT, [Version, Description]);
                  MyMessageBox(hDlg, APPNAME, s, 1);
                end
                else
                  Messagebox(hDlg, PChar(SysErrorMessage(dwReturn)), APPNAME, MB_ICONSTOP);
              end;
            IDC_BTN_START:
              begin
                SendDlgItemMessage(hDlg, IDC_IP_FROM, IPM_GETADDRESS, 0, Integer(@ip_from));
                SendDlgItemMessage(hDlg, IDC_IP_TO, IPM_GETADDRESS, 0, Integer(@ip_to));

                ip1_int := ToIP(FIRST_IPADDRESS(ip_from), SECOND_IPADDRESS(ip_from), THIRD_IPADDRESS(ip_from),
                  FOURTH_IPADDRESS(ip_from));
                ip2_int := ToIP(FIRST_IPADDRESS(ip_to), SECOND_IPADDRESS(ip_to), THIRD_IPADDRESS(ip_to),
                  FOURTH_IPADDRESS(ip_to));

                if ip1_int > ip2_int then
                begin
                  ip_temp := ip1_int;
                  ip1_int := ip2_int;
                  ip2_int := ip_temp;
                end;

                setlength(Range, 0);
                setlength(Range, ip2_int - ip1_int + 1);

                cnt := 0;
                for i := ip1_int to ip2_int do
                begin
                  Range[cnt] := IPToStr(i);
                  Inc(cnt);
                end;

                Start;
                SetTimer(hDlg, 0, 1000, nil);
                setlength(ThreadArray, 0);
                setlength(ThreadArray, MAXTHREADS);
                setlength(SubRange, 0);
                setlength(SubRange, MAXTHREADS);
                len := (length(Range) - 1) div MAXTHREADS + 1;
                for i := 0 to MAXTHREADS - 1 do
                begin
                  setlength(SubRange[i], len);
                  SubRange[i] := copy(Range, i * len, len);
                  New(ThreadParams);
                  SetLength(ThreadParams.Range, length(SubRange[i]));
                  ThreadParams.Range := SubRange[i];
                  ThreadArray[i] := BeginThread(nil, 0, @PingThread, ThreadParams, 0, ThreadID);
                end;

              end;
            IDC_BTN_CANCEL:
              begin
                SendDlgItemMessage(hDlg, IDC_SB, SB_SETICON, 4, LoadImage(HInstance, MAKEINTRESOURCE(8), IMAGE_ICON,
                  16, 16, LR_LOADTRANSPARENT));
                s := rsCancel;
                SendDlgItemMessage(hDlg, IDC_SB, SB_SETTEXT, 4, Integer(PChar(s)));
                EnableControl(hDlg, IDC_BTN_CANCEL, False);
                Terminate := True;
                for i := 0 to length(ThreadArray) - 1 do
                  TerminateThread(ThreadArray[i], 0);
                //Finished;
              end;
          end;
        end;
      end;
    WM_NOTIFY:
      begin
        with PNMHdr(lParam)^ do
        begin
          case code of
            LVN_COLUMNCLICK:
              begin
                if not Terminate then
                begin
                  ListView_SortItems(GetDlgItem(hDlg, IDC_LV), @CompareFunc, PNMListView(lParam)^.iSubItem);
                  SortLV(GetDlgItem(hDlg, IDC_LV));
                  SetHeader_RemoveBmp(hHeader, LastCol);
                  SetHeader_SortBmp(hHeader, PNMListView(lParam)^.iSubItem);
                  SortOrder := 1 - SortOrder;
                  LastCol := PNMListView(lParam)^.iSubItem;
                end;
              end;
            LVN_KEYDOWN:
              begin
                case PLVKeyDown(lParam)^.wvKey of
                  VK_SPACE:
                    begin
                      s := '\\' + GetItemCaption;
                      New(OpenParams);
                      OpenParams.Computer := s;
                      CloseHandle(BeginThread(nil, 0, @OpenThread, OpenParams, 0, ThreadID));
                    end;
                end;
              end;
            NM_DBLCLK:
              begin
                s := '\\' + GetItemCaption;
                New(OpenParams);
                OpenParams.Computer := s;
                CloseHandle(BeginThread(nil, 0, @OpenThread, OpenParams, 0, ThreadID));
              end;
          end;
        end;
      end;
  else
    result := false;
  end;
end;

var
  icc               : TInitCommonControlsEx = (
    dwSize: sizeof(TInitCommonControlsEx);
    dwICC: ICC_INTERNET_CLASSES or ICC_WIN95_CLASSES;
    );

begin
  InitializeCriticalSection(cs);
  InitCommonControls;
  InitCommonControlsEx(icc);
  DialogBox(SysInit.HInstance, MAKEINTRESOURCE(100), 0, @dlgfunc);
  DeleteCriticalSection(cs);
end.

