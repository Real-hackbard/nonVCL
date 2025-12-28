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

program NetSend;

uses
  windows,
  messages,
  CommCtrl,
  ShlObj,
  ActiveX,
  WinSvc,
  MpuTools in 'units\MpuTools.pas',
  constants in 'units\constants.pas',
  MpuAboutWnd in 'units\MpuAboutWnd.pas';

{$R .\res\resource.res}

type
  TThreadParams = record
    FParent: THandle;
    FMachine: string[255];
    FMsgText: string[255];
    FSender: string[255];
  end;
  PThreadParams = ^TThreadParams;

var
  hApp              : THandle;

resourcestring
  rsMessengerNotRunning = 'Messenger service is not running on %s.' + #13#10#13#10 +
    'In order to send messages with this program' + #13#10 +
    'the Messenger service must be running.';

function GetItemText(hParent: THandle; ID: Integer): string;
var
  p                 : PChar;
  len               : Integer;
  s                 : string;
begin
  p := nil;
  s := '';
  len := SendDlgItemMessage(hParent, ID, WM_GETTEXTLENGTH, 0, 0);
  if len > 0 then
  begin
    try
      p := GetMemory(len + 1);
      if Assigned(p) then
      begin
        GetDlgItemText(hParent, ID, p, len + 1);
        s := string(p);
      end;
    finally
      FreeMemory(p);
    end;
  end;
  result := s;
end;

function FindComputer(hWnd: THandle; sPrompt: string; csidl: word; var
  sComputer: string): boolean;
const
  BIF_NEWDIALOGSTYLE = $0040;
  BIF_USENEWUI      = BIF_NEWDIALOGSTYLE or BIF_EDITBOX;
  BIF_BROWSEINCLUDEURLS = $0080;
  BIF_UAHINT        = $0100;
  BIF_NONEWFOLDERBUTTON = $0200;
  BIF_NOTRANSLATETARGETS = $0400;
  BIF_SHAREABLE     = $8000;

  BFFM_IUNKNOWN     = 5;
  BFFM_SETOKTEXT    = WM_USER + 105; // Unicode only
  BFFM_SETEXPANDED  = WM_USER + 106; // Unicode only
var
  bi                : TBrowseInfo;
  ca                : array[0..MAX_PATH] of char;
  pidl, pidlSelected: PItemIDList;
  m                 : IMalloc;
begin
  if Failed(SHGetSpecialFolderLocation(hWnd, CSIDL_NETWORK, pidl)) then
  begin
    result := False;
    exit;
  end;
  try
    FillChar(bi, SizeOf(bi), 0);
    with bi do
    begin
      hwndOwner := hWnd;
      pidlRoot := pidl;
      pszDisplayName := ca;
      lpszTitle := PChar(sPrompt);
      ulFlags := BIF_BROWSEFORCOMPUTER;
    end;
    pidlSelected := SHBrowseForFolder(bi);
    Result := Assigned(pidlSelected);
    if Result then
      sComputer := '\\' + string(ca);
  finally
    if Succeeded(SHGetMalloc(m)) then
      m.Free(pidl);
  end;
end;

function ServiceGetStatus(sMachine, sService: PChar): DWORD; 
  {******************************************} 
  {*** Parameters: ***} 
  {*** sService: specifies the name of the service to open 
  {*** sMachine: specifies the name of the target computer 
  {*** ***} 
  {*** Return Values: ***} 
  {*** -1 = Error opening service ***} 
  {*** 1 = SERVICE_STOPPED ***} 
  {*** 2 = SERVICE_START_PENDING ***} 
  {*** 3 = SERVICE_STOP_PENDING ***} 
  {*** 4 = SERVICE_RUNNING ***} 
  {*** 5 = SERVICE_CONTINUE_PENDING ***} 
  {*** 6 = SERVICE_PAUSE_PENDING ***} 
  {*** 7 = SERVICE_PAUSED ***} 
  {******************************************} 
var 
  SCManHandle, SvcHandle: SC_Handle; 
  SS: TServiceStatus; 
  dwStat: DWORD; 
begin 
  dwStat := 0; 
  // Open service manager handle. 
  SCManHandle := OpenSCManager(sMachine, nil, SC_MANAGER_CONNECT); 
  if (SCManHandle > 0) then 
  begin 
    SvcHandle := OpenService(SCManHandle, sService, SERVICE_QUERY_STATUS); 
    // if Service installed 
    if (SvcHandle > 0) then 
    begin 
      // SS structure holds the service status (TServiceStatus); 
      if (QueryServiceStatus(SvcHandle, SS)) then 
        dwStat := ss.dwCurrentState; 
      CloseServiceHandle(SvcHandle); 
    end; 
    CloseServiceHandle(SCManHandle); 
  end; 
  Result := dwStat; 
end;

function IsServiceRunning(sMachine, sService: PChar): Boolean;
begin
  Result := SERVICE_RUNNING = ServiceGetStatus(sMachine, sService);
end;

function SendToMailSlot(const Machine, Slot, MsgText: string): Boolean;
var
  CompleteSlot      : string;
  hSlot             : THandle;
  BytesWritten      : DWORD;
begin
  BytesWritten := 0;
  CompleteSlot := '\\' + Machine + '\mailslot\' + Slot;

  hSlot := CreateFile(PChar(CompleteSlot), GENERIC_WRITE, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);

  if hSlot <> INVALID_HANDLE_VALUE then
  begin
    if (WriteFile(hSlot, Pointer(PChar(MsgText))^, length(MsgText), BytesWritten, nil)) and (BytesWritten =
      length(MsgText)) then
    begin
      Result := True;
    end
    else
      Result := False;
    CloseHandle(hSlot);
  end
  else
    Result := False;
end;

function ThreadFunc(p: PThreadParams): DWORD;
var
  Parent            : THandle;
  machine           : string;
  msgtext           : string;
  sender            : string;
  msg               : string;
begin
  Parent := PThreadParams(p)^.FParent;
  machine := PThreadParams(p)^.FMachine;
  msgtext := PThreadParams(p)^.FMsgText;
  sender := PThreadParams(p)^.FSender;

  msg := machine + #0 + sender + #0 + msgtext;

  if not SendToMailSlot(machine, 'messngr', msg) then
  begin
    MessageBox(Parent, PChar(SysErrorMessage(GetLastError)), APPNAME, MB_ICONERROR);
    EnableControl(Parent, IDC_BTN_SEND, True);
  end
  else
  begin
    SetDlgItemText(Parent, IDC_EDT_MSG, nil);
  end;

  Dispose(p);
  Result := 0;
end;

function dlgfunc(hDlg: hWnd; uMsg: dword; wParam: wParam; lParam: lParam): bool;
  stdcall;
var
  MyFont            : HFONT;
  s                 : string;
  i                 : Integer;
  rect              : TRect;
  pt                : TPoint;
  b                 : Boolean;
  machine           : string;
  msgtext           : string;
  sender            : string;
  tp                : PThreadParams;
  ThreadID          : Cardinal;
begin
  result := true;
  case uMsg of
    WM_INITDIALOG:
      begin
        hApp := hDlg;
        // Dialog icon
        if SendMessage(hDlg, WM_SETICON, ICON_SMALL, Integer(LoadIcon(hInstance, MAKEINTRESOURCE(1)))) = 0 then
          SendMessage(hDlg, WM_SETICON, ICON_BIG, Integer(LoadIcon(hInstance, MAKEINTRESOURCE(1))));
        // Banner font
        MyFont := CreateFont(FONTSIZE, 0, 0, 0, 900, 0, 0, 0, ANSI_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
          DEFAULT_QUALITY, DEFAULT_PITCH, FONTNAME);
        if MyFont <> 0 then
          SendDlgItemMessage(hDlg, IDC_STC_BANNER, WM_SETFONT, Integer(MyFont), Integer(true));
        // Window caption and banner caption
        s := APPNAME;
        SetWindowText(hDlg, PChar(s));
        SetDlgItemText(hDlg, IDC_STC_BANNER, PChar(s));
        // Tooltips
        if CreateToolTips(hDlg) then
        begin
          for i := IDC_BTN_ABOUT to IDC_BTN_SEND do
            AddToolTip(hDlg, i, @ti, TOOLTIPS[i - IDC_BTN_ABOUT]);
        end;

        SendDlgItemMessage(hDlg, IDC_EDT_MSG, EM_SETLIMITTEXT, 254, 0); 
        SetDlgItemText(hDlg, IDC_EDT_SENDER, PChar(GetCompName));
        EnableControl(hDlg, IDC_BTN_SEND, False);
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
        MoveWindow(GetDlgItem(hDlg, IDC_STC_BANNER), 0, 0, loword(lParam), 75, TRUE);
        s := APPNAME;
        SetDlgItemText(hDlg, IDC_STC_BANNER, pointer(s));
        SetWindowPos(GetDlgItem(hDlg, IDC_BTN_ABOUT), GetDlgItem(hDlg, IDC_STC_BANNER), loword(lParam) - 47, 7, 40, 22,
          0);
        GetWindowRect(GetDlgItem(hDlg, IDC_STC_BANNER), rect);
        pt.X := rect.Left;
        pt.Y := rect.Bottom;
        ScreenToClient(hDlg, pt);
        MoveWindow(GetDlgItem(hDlg, IDC_STC_DEVIDER), 0, pt.Y, rect.Right - rect.Left, 2, True);
      end;
    WM_CLOSE:
      begin
        EndDialog(hDlg, 0);
      end;
    WM_COMMAND:
      begin
        { accel for closing the dialog with ESC }
        if wParam = ID_CANCEL then
          SendMessage(hDlg, WM_CLOSE, 0, 0);
        if hiword(wParam) = EN_CHANGE then
        begin
          case loword(wParam) of
            IDC_EDT_COMPUTER, IDC_EDT_MSG:
              begin
                b := (SendMessage(GetDlgItem(hDlg, IDC_EDT_COMPUTER), WM_GETTEXTLENGTH, 0, 0) > 0) and
                  (SendMessage(GetDlgItem(hDlg, IDC_EDT_MSG), WM_GETTEXTLENGTH, 0, 0) > 0);
                EnableControl(hDlg, IDC_BTN_SEND, b);
              end;
          end;
        end;
        { button and menu clicks }
        if hiword(wParam) = BN_CLICKED then
        begin
          case LoWord(wParam) of
            IDC_BTN_ABOUT:
              begin
                TAboutWnd.ShowAboutWnd(hDlg);
              end;
            IDC_BTN_COMPUTER:
              begin
                if FindComputer(hDlg, 'Computer suchen', 0, s) then
                begin
                  SetDlgItemText(hDlg, IDC_EDT_COMPUTER, PChar(copy(s, 3, length(s))));
                end;
              end;
            IDC_BTN_SEND:
              begin
                // check Messenger service on local machine
                if not IsServiceRunning(PChar(GetCompName), 'Messenger') then
                begin
                  MessageBox(hDlg, PChar(Format(rsMessengerNotRunning, [GetCompName])), PChar(APPNAME), MB_ICONINFORMATION);
                  exit;
                end;
                // check Messenger service on remote machine
                machine := GetItemText(hDlg, IDC_EDT_COMPUTER);
                if IsServiceRunning(PChar(Format(rsMessengerNotRunning, [machine])), 'Messenger') then
                begin
                  MessageBox(hDlg, PChar(Format(rsMessengerNotRunning, [machine])), PChar(APPNAME), MB_ICONINFORMATION);
                  exit;
                end;

                msgtext := GetItemtext(hDlg, IDC_EDT_MSG);
                sender := GetItemText(hDlg, IDC_EDT_SENDER);
                if sender = '' then
                  sender := GetCompName;

                New(tp);          
                tp.FParent := hDlg;
                tp.FMachine := machine;
                tp.FMsgText := msgtext;
                tp.FSender := sender;

                EnableWindow(GetDlgItem(hDlg, IDC_BTN_SEND), False);

                CloseHandle(BeginThread(nil, 0, @ThreadFunc, tp, 0, ThreadID));

                SetFocus(GetDlgItem(hDlg, IDC_EDT_MSG));
              end;
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

