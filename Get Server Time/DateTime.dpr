program DateTime;

{.$DEFINE DYNAMIC_PCHAR}

uses
  Windows,
  Messages,
  ShellAPI,
  WinSock,
  WinInet,
  MSysUtils in 'MSysUtils.pas';


{$R DateTime.res}



//
// Date, & Time
//
var
{$IFDEF DYNAMIC_PCHAR}
  lpBuf: pchar;
  iLen: integer;
{$ELSE}
  lpBuf: array[0..MAX_PATH] of char;
{$ENDIF}


procedure FormatTime(const wnd: HWND; const st: TSystemTime);
begin
{$IFDEF DYNAMIC_PCHAR}
  iLen := GetTimeFormat(LOCALE_USER_DEFAULT,TIME_FORCE24HOURFORMAT,
    @st,nil,nil,0);

  GetMem(lpBuf,iLen);
  try
    ZeroMemory(lpBuf,iLen);

    if(GetTimeFormat(LOCALE_USER_DEFAULT,TIME_FORCE24HOURFORMAT,
      @st,nil,lpBuf,iLen) = iLen) then SetWindowText(wnd,lpBuf);
  finally
    FreeMem(lpBuf,iLen);
  end;
{$ELSE}
  ZeroMemory(@lpBuf,sizeof(lpBuf));

  if(GetTimeFormat(LOCALE_USER_DEFAULT,TIME_FORCE24HOURFORMAT,
    @st,nil,lpBuf,sizeof(lpBuf)) = 0) then
  begin
    // Format "hh:mm:ss" is used as an alternative
    lstrcpy(lpBuf,pchar(Format('%.2d:%.2d:%.2d',[st.wHour,st.wMinute,st.wSecond])));
  end;

  SetWindowText(wnd,lpBuf);
{$ENDIF}
end;

procedure FormatDate(const wnd: HWND);
var
  st : TSystemTime;
begin
{$IFDEF DYNAMIC_PCHAR}
  iLen := GetDateFormat(LOCALE_USER_DEFAULT,DATE_SHORTDATE,
    nil,nil,nil,0);

  GetMem(lpBuf,iLen);
  try
    ZeroMemory(lpBuf,iLen);

    if(GetDateFormat(LOCALE_USER_DEFAULT,DATE_SHORTDATE,
      nil,nil,lpBuf,iLen) = iLen) then SetWindowText(wnd, lpBuf);
  finally
    FreeMem(lpBuf,iLen);
  end;
{$ELSE}
  ZeroMemory(@lpBuf,sizeof(lpBuf));

  if(GetDateFormat(LOCALE_USER_DEFAULT,DATE_SHORTDATE,
    nil,nil,lpBuf,sizeof(lpBuf)) = 0) then
  begin
    // Format "JJJJ-MM-TT" is used as an alternative
    GetLocalTime(st);
    lstrcpy(lpBuf, pchar(Format('%.4d-%.2d-%.2d', [st.wYear, st.wMonth, st.wDay])));
  end;

  SetWindowText(wnd,lpBuf);
{$ENDIF}
end;


{ ------------------------------------------------------------------------------------ }

//
// Read the list of time servers from the INI file
//
const
  szDateTimeIni = 'DateTime.ini';
  szIniKey      = 'serverlist';
  BUFSIZE       = 16348;

procedure LoadTimeServers(hCombobox: HWND);
var
  buf, p        : pchar;
  kl            : array of string;
  i             : integer;
begin
  // Clear the contents of the combo box
  SendMessage(hCombobox,CB_RESETCONTENT,0,0);

  // Reading topic names from the INI file
  GetMem(buf,BUFSIZE);
  try
    SetLength(kl,0);
    if(GetPrivateProfileString(szIniKey,nil,nil,buf,BUFSIZE,
      pchar(ExtractFilePath(paramstr(0)) + szDateTimeIni)) <> 0) then
    begin
      p := buf;
      while(p^ <> #0) do begin
        SetLength(kl,length(kl)+1);
        kl[length(kl)-1] := p;

        inc(p,lstrlen(p)+1);
      end;
    end;
  finally
    FreeMem(buf,BUFSIZE);
  end;

  // Read values ??from the INI file and enter them into the combobox.
  if(length(kl) > 0) then begin
    GetMem(buf,BUFSIZE);
    try
      for i := 0 to length(kl)-1 do begin
        ZeroMemory(buf,BUFSIZE);
        if(GetPrivateProfileString(szIniKey,@kl[i][1],nil,
          buf,BUFSIZE,pchar(ExtractFilePath(paramstr(0)) + szDateTimeIni)) <> 0) then

        SendMessage(hCombobox,CB_ADDSTRING,0,LPARAM(buf));
      end;
    finally
      FreeMem(buf,BUFSIZE);
    end;

    SetLength(kl,0);
  end;

  // Select entry if available
  if(SendMessage(hCombobox,CB_GETCOUNT,0,0) > 0) then
    SendMessage(hCombobox,CB_SETCURSEL,0,0);
end;

//
// Is there an online connection?
//
function IsOnline(URL: LPCSTR; Ip: PDWORD): boolean;
var
  hostent : PHostEnt;
begin
  Result                 := InternetGetConnectedState(nil,0);
  if(Ip <> nil) then Ip^ := 0;

  if(Result) and (URL <> nil) then begin
    hostent              := gethostbyname(URL);
    Result               := (hostent <> nil);

    if(Result) and (Ip <> nil) then
      Ip^                := integer(pointer(hostent^.h_addr_list^)^);
  end;
end;

//
// Connect to the server and get time
//
procedure GetDateTimeFromServer(const hCombobox, hServerDate,
  hServerTime: HWND);
label
  SocketClose;
var
  buf             : array[0..MAX_PATH]of char;
  idx             : integer;
  dwIp            : dword;
  s               : TSocket;
  saddr           : TSockAddr;
  res             : integer;
  iTime           : dword;
  st              : TSystemTime;
  ft              : TFileTime;
  li              : ULARGE_INTEGER;
begin
  // Retrieve the server name
  idx := SendMessage(hCombobox,CB_GETCURSEL,0,0);
  if(idx = CB_ERR) then exit;
  ZeroMemory(@buf,sizeof(buf));
  if(SendMessage(hCombobox,CB_GETLBTEXT,idx,LPARAM(@buf)) = CB_ERR) then exit;

  // Is the server (or the program) (still) online?
  if(not IsOnline(buf,@dwIp)) or (dwIp = 0) then exit;

  s := socket(AF_INET,SOCK_STREAM,0);
  if(s <> INVALID_SOCKET) then begin
    saddr.sin_family      := AF_INET;
    saddr.sin_addr.S_addr := dwIp;
    saddr.sin_port        := htons(37);

    res                   := connect(s,saddr,sizeof(TSockAddr));
    if(res <> SOCKET_ERROR) then
      res                 := recv(s,iTime,sizeof(iTime),0);

    if(res <> SOCKET_ERROR) then begin
      iTime               := htonl(iTime);

      st.wYear            := 1900;
      st.wMonth           := 1;
      st.wDayOfWeek       := 0;
      st.wDay             := 1;
      st.wHour            := 0;
      st.wMinute          := 0;
      st.wSecond          := 0;
      st.wMilliseconds    := 0;
      if(not SystemTimeToFileTime(st,ft)) then goto SocketClose;

      li.QuadPart         := (int64(iTime) * 10000000) +
        ULARGE_INTEGER(ft).QuadPart;
      if(not FileTimeToSystemTime(TFileTime(li),st)) then goto SocketClose;

      // Show server time
      ZeroMemory(@buf,sizeof(buf));
      if(GetTimeFormat(LOCALE_USER_DEFAULT,TIME_FORCE24HOURFORMAT,
        @st,nil,buf,sizeof(buf)) > 0) then SetWindowText(hServerTime,buf);

      // Show server date
      ZeroMemory(@buf,sizeof(buf));
      if(GetDateFormat(LOCALE_USER_DEFAULT,DATE_SHORTDATE,@st,
        nil,buf,sizeof(buf)) > 0) then SetWindowText(hServerDate,buf);
    end;

SocketClose:
    CloseSocket(s);
  end;
end;


{ ------------------------------------------------------------------------------------ }

//
// "dlgproc"
//
const
  IDC_LOCALTIME  = 110;
  IDC_UTCTIME    = 111;
  IDC_DATE       = 112;
  IDC_LOCALEBTN  = 120;
  IDC_TIMESERVER = 130;
  IDC_SVRTIME    = 131;
  IDC_SVRDATE    = 132;
  IDC_GETTIMEBTN = 133;
  IDC_TIMER      = 2;
var
  lSysTime       : TSystemTime;
  hTimer         : uint    = 0;
  fImOnline      : boolean = false;


function dlgproc(hwndDlg: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM): bool; stdcall;
begin
  Result := true;

  case uMsg of
    WM_INITDIALOG:
      begin
        // Load list of time servers
        LoadTimeServers(GetDlgItem(hwndDlg,IDC_TIMESERVER));

        // Create a 1-second timer
        hTimer := SetTimer(hwndDlg,IDC_TIMER,1000,nil);
      end;
    WM_COMMAND:
      case HIWORD(wp) of
        BN_CLICKED:
          case LOWORD(wp) of
            IDC_LOCALEBTN:
              ShellExecute(hwndDlg,'open','rundll32.exe',
                'shell32.dll,Control_RunDLL intl.cpl',nil,SW_SHOWNORMAL);
            IDC_GETTIMEBTN:
              begin
                EnableWindow(GetDlgItem(hwndDlg,LOWORD(wp)),false);

                GetDateTimeFromServer(GetDlgItem(hwndDlg,IDC_TIMESERVER),
                  GetDlgItem(hwndDlg,IDC_SVRTIME),
                  GetDlgItem(hwndDlg,IDC_SVRDATE));

                EnableWindow(GetDlgItem(hwndDlg,LOWORD(wp)),true);
              end;
          end;
        CBN_SELCHANGE:
          if(LOWORD(wp) = IDC_TIMESERVER) then begin
            SetWindowText(GetDlgItem(hwndDlg,IDC_SVRTIME),nil);
            SetWindowText(GetDlgItem(hwndDlg,IDC_SVRDATE),nil);
          end;
        end;
    WM_TIMER:
      if(wp = IDC_TIMER) then begin
        GetSystemTime(lSysTime);
        FormatTime(GetDlgItem(hwndDlg,IDC_UTCTIME),lSysTime);

        GetLocalTime(lSysTime);
        FormatTime(GetDlgItem(hwndDlg,IDC_LOCALTIME),lSysTime);
        FormatDate(GetDlgItem(hwndDlg,IDC_DATE));

        // Is there an online connection?
        fImOnline := IsOnline('www.microsoft.com',nil);
        EnableWindow(GetDlgItem(hwndDlg,IDC_GETTIMEBTN),fImOnline);
        EnableWindow(GetDlgItem(hwndDlg,IDC_TIMESERVER),fImOnline);
      end;
    WM_CLOSE:
      begin
        KillTimer(hwndDlg,IDC_TIMER);
        EndDialog(hwndDlg,0);
      end;
  else
    Result := false;
  end;
end;

//
// WinMain
//
var
  wsadata : TWsaData;
begin
  if(WSAStartup(MAKEWORD(1,1),wsadata) <> 0) then begin
    MessageBox(0,'WinSock-Error',nil,0);
    Halt;
  end;

  DialogBox(hInstance,MAKEINTRESOURCE(100),0,@dlgproc);

  WsaCleanup;
end.
