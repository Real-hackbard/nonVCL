{$INCLUDE CompilerSwitches.inc}
{.$define DEMO}

{$R 'res\resource.res'}

program PasswordRecover;

uses
  windows,
  messages{$IFDEF DEBUGGING},
  SysUtils{$ENDIF},
  MPuTools in 'units\MpuTools.pas',
  CommCtrl,
  ShellAPI,
  MpuNTUser in 'units\MpuNTUser.pas',
  SSPIValidatePassword in 'units\SSPIValidatePassword.pas',
  MPuBruteForce in 'units\MPuBruteForce.pas',
  MpuAboutWnd in 'units\MpuAboutWnd.pas';

const
  IDC_BTN_GO = 104;
  IDC_STC_BANNER = 101;
  IDC_STC_DEVIDER = 102;
  IDC_BTN_ABOUT = 103;
  IDC_LST_USER = 105;
  IDC_STC_USER = 106;
  IDC_EDT_CHARS = 114;
  IDC_EDT_PW = 109;
  IDC_BTN_CANCEL = 110;
  IDC_STATBAR = 112;
  IDC_EDT_MINLEN = 117;
  IDC_UD_MINLEN = 118;
  IDC_EDT_MAXLEN = 121;
  IDC_UD_MAXLEN = 120;
  IDC_OPT_BF = 122;
  IDC_OPT_FILE = 123;
  IDC_EDT_FILE = 124;
  IDC_BTN_FILE = 125;

  TNA_MSG = WM_USER + 20;

  FONTNAME = 'Tahoma';
  FONTSIZE = -18;

const
  APPNAME = 'PasswordRecover';
  INFO_TEXT = APPNAME + ' %s' + #13#10 + '%s' + #13#10#13#10 +
    'Copyright © Your Name' + #13#10#13#10 +
    'Homepage: https://github.com';
  COPYRIGHT = 'Copyright © Your Name';
  HOMEPAGE = 'https://github.com';

const
{$IFDEF DEMO}
  ch = 'abcdefghijklmnopqrstuvwxyz';
{$ELSE}
  ch =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz°!"§$%&/()=?`´\}][{^+*~''#_:.,;<>|@ ';
{$ENDIF}

var
  hApp: THandle;
  bFirstTime: Boolean = True;
  TaskBarNewReg: DWORD;
  IconData: TNotifyIconData;
  IDTimer: Integer;
  Terminate: Boolean = False;
  bUp: Boolean = True;
  idxico: Cardinal = 1;
  User: string;
  PW: string;
  PWFound: Boolean;
  CntPW: Integer;
  cs: RTL_CRITICAL_SECTION;
  CountLines: Integer;

type
  TBFThreadParams = record
    User: string[255];
    Chars: string[255];
    MinLen: Integer;
    MaxLen: Integer;
  end;
  PBFThreadParams = ^TBFThreadParams;

  TDictThreadParams = record
    DictFile: string[255];
    User: string[255];
  end;
  PDictThreadParams = ^TDictThreadParams;

resourcestring
  rsUser = '%s';
  rsPW = '%s';
  rsPercent = '%d%%';
  rsFound = 'User: %s' + #13#10 + 'Password: %s';
  rsNotFound = 'No password found.';
  rsHomeHint = 'You are running Windows XP Home Edition,' + #13#10 +
    'therefore this program might not run properly.';

////////////////////////////////////////////////////////////////////////////////

function CountTextFileLines(Filename: string): Integer;
var
  F: TextFile;
  Buf: array[1..4096] of Char;
  Count: Integer;
  s: string;
begin
  Count := 0;
  AssignFile(F, Filename);
  SetTextBuf(F, Buf, sizeof(Buf));
{$I-}
  Reset(F);
{$I+}
  if IOResult = 0 then
  begin
    while not EOF(F) do
    begin
      Readln(F, s);
      Inc(Count);
    end;
    CloseFile(F);
  end;
  Result := Count;
end;

procedure SetStatusbar(Handle: THandle; lParam: LPARAM; wParam: WPARAM);
var
  Panels: array[0..2] of Integer;
begin
  //SetWindowPos(GetDlgItem(Handle, IDC_STATBAR), 0, 0, hiword(lParam) - 22, loword(lParam), 0, SWP_SHOWWINDOW);
  Panels[0] := loword(lParam) - 170;
  Panels[1] := loword(lParam) - 50;
  Panels[2] := -1;
  SendDlgItemMessage(Handle, IDC_STATBAR, SB_SETPARTS, 3, Integer(@Panels));
end;

function FormatTime(t: int64): string; { (gettime by Assarbad) }
begin
  //result := IntToStr(t mod 1000);
  case t mod 1000 < 100 of
    true: result := {'0' +} result;
  end;
  t := t div 1000; // -> seconds
  result := IntToStr(t mod 60) + ' sec ' + result;
  case t mod 60 < 10 of
    true: result := '0' + result;
  end;
  t := t div 60; //minutes
  result := IntToStr(t mod 60) + ' min ' + result;
  case t mod 60 < 10 of
    true: result := '0' + result;
  end;
  t := t div 60; //hours
  result := IntToStr(t mod 24) + ' hrs ' + result;
  case t mod 60 < 10 of
    true: result := '0' + result;
  end;
  result := IntToStr(t div 24) + ' d ' + result;
end;

function SetCheck(bCheck: Boolean): DWORD;
begin
  if bCheck then
    Result := BST_CHECKED
  else
    Result := BST_UNCHECKED;
end;

function GetCheck(hDlg: THandle; ID: DWORD): Boolean;
begin
  Result := IsDlgButtonChecked(hDlg, ID) = BST_CHECKED;
end;

procedure MakeColumns;
var
  hLV: THandle;
  lvc: TLVColumn;
resourcestring
  rsDescription = 'Benutzer';
begin
  hLV := GetDlgItem(hApp, IDC_LST_USER);
  lvc.mask := LVCF_TEXT or LVCF_WIDTH;
  lvc.pszText := PChar(rsDescription);
  lvc.cx := 220;
  SendMessage(hLV, LVM_INSERTCOLUMN, 0, Integer(@lvc));
end;

function EnumUsersCallback(Username: string; cntUsers: Integer; Data: Pointer): Boolean;
var
  lvi: TLVItem;
begin
  FillChar(lvi, sizeof(lvi), #0);
  lvi.mask := LVIF_TEXT or LVIF_IMAGE;
  lvi.iSubItem := 0;
  lvi.iImage := 0;
  lvi.pszText := PChar(Username);
  SendDlgItemMessage(hApp, IDC_LST_USER, LVM_INSERTITEM, 0, Integer(@lvi));
  result := True;
end;

////////////////////////////////////////////////////////////////////////////////

function BruteForceThread(p: PBFThreadParams): Integer;
var
  User: string;
  Chars: string;
  MinLen: Integer;
  MaxLen: Integer;
  MaxChars: Int64;
  s: string;
begin
  User := PBFThreadParams(p)^.User;
  Chars := PBFThreadParams(p)^.Chars;
  Minlen := PBFThreadParams(p)^.MinLen;
  MaxLen := PBFThreadParams(p)^.MaxLen;
  MaxChars := MaxKombinations(MinLen, Chars);
  while (length(s) <= Maxlen) and (not Terminate) do
  begin
    s := BruteForce(MaxChars, Chars);
    EnterCriticalSection(cs);
    Inc(CntPW);
    if s <> '' then
      PWFound := SSPLogonUser(GetCompName, User, s);
    SendDlgItemMessage(hApp, IDC_STATBAR, SB_SETTEXT, 1, Integer(Format(rsPW, [@s[1]])));
    LeaveCriticalSection(cs);
    Inc(MaxChars);
    Sleep(0);
    if PWFound then
    begin
      PW := s;
      Terminate := True;
    end;
  end;
  Dispose(p);
  result := 0;
end;

function BruteForceThreadManager(p: PBFThreadParams): Integer;
var
  Threads: array of THandle;
  len: Integer;
  i: Integer;
  BFThreadParams: PBFThreadParams;
  ThreadID: Cardinal;
  hIcon: THandle;
  s: string;
begin
  PWFound := False;
  Terminate := False;
  CntPW := 0;

  InitializeCriticalSection(cs);

  len := PBFThreadParams(p)^.MaxLen - PBFThreadParams(p)^.MinLen + 1;
  SetLength(Threads, len);
  PWFound := False;
  for i := 0 to len - 1 do
  begin
    New(BFThreadParams);
    BFThreadParams.User := PBFThreadParams(p)^.User;
    BFThreadParams.Chars := PBFThreadparams(p)^.Chars;
    BFThreadParams.MinLen := PBFThreadParams(p)^.MinLen;
    BFThreadParams.MaxLen := PBFThreadParams(p)^.MaxLen - i;
    Threads[i] := BeginThread(nil, 0, @BruteForceThread, BFThreadParams, 0, ThreadID);
  end;
  WaitForMultipleObjects(Length(Threads), @Threads[0], True, INFINITE);

  DeleteCriticalSection(cs);

  if PWFound then
  begin
    s := Format(rsFound, [User, PW]);
    Messagebox(hApp, PChar(s), APPNAME, MB_ICONINFORMATION);
  end
  else
  begin
    s := rsNotFound;
    Messagebox(hApp, PChar(s), APPNAME, MB_ICONINFORMATION);
  end;

  KillTimer(hApp, IDTimer);
  // GUI stuff
  hIcon := LoadIcon(HInstance, MAKEINTRESOURCE(1));
  SendMessage(hApp, WM_SETICON, ICON_BIG, hIcon);
  SendMessage(hApp, WM_SETICON, ICON_SMALL, hIcon);
  EnableControl(hApp, IDC_BTN_CANCEL, False);
  EnableControl(hApp, IDC_BTN_GO, True);
  EnableControl(hApp, IDC_LST_USER, True);

  Dispose(p);
  result := 0;
end;

function DictThread(p: PDictThreadParams): Integer;
var
  DictFile: string;
  User: string;
  F: TextFile;
  Buf: array[1..4096] of Char;
  PW: string;
  bFound: Boolean;
  s: string;
  hIcon: THandle;
  PercentDone: Integer;
  cnt: Integer;
begin
  result := 0;
  // Reset everything and initializations
  PW := '';
  bFound := False;
  Terminate := False;
  DictFile := p.DictFile;
  User := p.User;
  cnt := 0;

  AssignFile(F, DictFile);
  SetTextBuf(F, Buf, sizeof(Buf));
{$I-}
  Reset(F);
{$I+}
  if IOResult = 0 then
  begin
    while (not bFound) and (not EOF(F)) and (not Terminate) do
    begin
      ReadLn(F, PW);
      Inc(cnt);
      if pos('#', PW) = 1 then
        Continue;
      SendDlgItemMessage(hApp, IDC_STATBAR, SB_SETTEXT, 1, Integer(Format(rsPW, [@PW[1]])));
      PercentDone := cnt * 100 div CountLines;
      SendDlgItemMessage(hApp, IDC_STATBAR, SB_SETTEXT, 2, Integer(Format(rsPercent, [PercentDone])));
      bFound := SSPLogonUser(GetCompName, User, PW);
    end;
    CloseFile(F);
  end
  else
    result := GetLastError;

  KillTimer(hApp, idTimer);
  if bFound then
  begin
    s := Format(rsFound, [User, PW]);
    Messagebox(hApp, PChar(s), APPNAME, MB_ICONINFORMATION);
  end
  else
  begin
    s := rsNotFound;
    Messagebox(hApp, PChar(s), APPNAME, MB_ICONINFORMATION);
  end;
  // GUI stuff
  hIcon := LoadIcon(HInstance, MAKEINTRESOURCE(1));
  SendMessage(hApp, WM_SETICON, ICON_BIG, hIcon);
  SendMessage(hApp, WM_SETICON, ICON_SMALL, hIcon);
  EnableControl(hApp, IDC_BTN_CANCEL, False);
  EnableControl(hApp, IDC_BTN_GO, True);
  EnableControl(hApp, IDC_LST_USER, True);
  Dispose(p);
  if result <> 0 then
    MessageboxW(hApp, PWideChar(SysErrorMessage(result)), APPNAME, MB_ICONSTOP);
end;

function dlgfunc(hDlg: hWnd; uMsg: dword; wParam: wParam; lParam: lParam): bool; stdcall;
var
  MyFont: HFONT;
  s: string;
  rect: TRect;
  pt: TPoint;
  Buffer: array[0..255] of Char;
  bTrans: Bool;
  BFThreadParams: PBFThreadParams;
  DictThreadParams: PDictThreadParams;
  ThreadID: Cardinal;
  hIcon: THandle;
  ImgList: THandle;
  lvi: TLVItem;
  UserModalsInfo: TUser_Modals_Info_0;
  MinPWLen: Cardinal;
  MinLen: Integer;
  MaxLen: Integer;
  ps: TPaintStruct;
  OSVer: TOSVersionInfoEx;
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
        {$ifdef DEMO}
        s := APPNAME + ' DEMO';
        {$else}
        s := APPNAME;
        {$endif}
        SetWindowText(hDlg, pointer(s));
        SetDlgItemText(hDlg, IDC_STC_BANNER, pointer(s));
        // TNA stuff
        TaskBarNewReg := RegisterWindowMessage('TaskbarCreated');
        // IconData Struktur füllen
        IconData.cbSize := SizeOf(IconData);
        IconData.Wnd := hDlg;
        IconData.uID := 100;
        IconData.uFlags := NIF_MESSAGE + NIF_ICON + NIF_TIP;
        IconData.uCallBackMessage := TNA_MSG;
        IconData.hIcon := LoadIcon(hInstance, MAKEINTRESOURCE(1));
        IconData.szTip := APPNAME;
        CheckDlgButton(hDlg, IDC_OPT_BF, SetCheck(True));
        EnableControl(hDlg, IDC_EDT_FILE, False);
        EnableControl(hDlg, IDC_BTN_FILE, False);
        // Listview stuff
        ImgList := ImageList_Create(16, 16, ILC_COLORDDB or ILC_MASK, 1, 0);
        hIcon := LoadIcon(hInstance, MAKEINTRESOURCE(6));
        ImageList_AddIcon(ImgList, hIcon);
        ListView_SetImageList(GetDlgItem(hDlg, IDC_LST_USER), ImgList, LVSIL_SMALL);
        MakeColumns;
        EnumUsers(GetCompName, FILTER_NORMAL_ACCOUNT, @EnumUsersCallback, nil);

        UserModalsInfo := UserModalsGet(GetCompName);
        MinPWLen := UserModalsInfo.usrmod0_min_passwd_len;

        // UpDown Controls
        SendDlgItemMessage(hDlg, IDC_UD_MINLEN, UDM_SETRANGE, 0, MAKELONG(14, MinPWLen));
        SendDlgItemMessage(hDlg, IDC_UD_MINLEN, UDM_SETPOS, 0, MinPWLen);
        SendDlgItemMessage(hDlg, IDC_UD_MAXLEN, UDM_SETRANGE, 0, MAKELONG(14, 0));
        SendDlgItemMessage(hDlg, IDC_UD_MAXLEN, UDM_SETPOS, 0, 14);
        EnableControl(hDlg, IDC_EDT_CHARS, True);
        SetDlgItemText(hDlg, IDC_EDT_CHARS, PChar(ch));
      end;
    WM_PAINT:
      begin
        BeginPaint(hDlg, ps);
        if bFirstTime then
        begin
          bFirstTime := False;
          if GetOSVersionInfo(OSVer) then
          begin
            if (OSVer.dwMajorVersion = 5) and (OSVer.dwMinorVersion = 1) then
            begin
              if (OSVer.dwOSVersionInfoSize >= SizeOf(TOSVersionInfoEx)) and (OSVer.wSuiteMask and VER_SUITE_PERSONAL
                <>
                0) then
                Messagebox(hDlg, PChar(rsHomeHint), APPNAME, MB_ICONWARNING);
            end;
          end
          else
            MessageboxW(hDlg, PWideChar(SysErrorMessage(GetLastError)), APPNAME, MB_ICONSTOP);
        end;
        Endpaint(hDlg, ps);
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
    { move the window with the left mouse button down }
    WM_LBUTTONDOWN:
      begin
        SetCursor(LoadCursor(0, IDC_SIZEALL));
        SendMessage(hDlg, WM_NCLBUTTONDOWN, HTCAPTION, lParam);
      end;
    WM_SIZE:
      begin
        MoveWindow(GetDlgItem(hDlg, IDC_STC_BANNER), 0, 0, loword(lParam), 75, TRUE);
        {$ifdef DEMO}
        s := APPNAME + ' DEMO';
        {$else}
        s := APPNAME;
        {$endif}
        SetDlgItemText(hDlg, IDC_STC_BANNER, pointer(s));
        SetWindowPos(GetDlgItem(hDlg, IDC_BTN_ABOUT), GetDlgItem(hDlg, IDC_STC_BANNER), loword(lParam) - 47, 7, 40, 22,
          0);
        GetWindowRect(GetDlgItem(hDlg, IDC_STC_BANNER), rect);
        pt.X := rect.Left;
        pt.Y := rect.Bottom;
        ScreenToClient(hDlg, pt);
        MoveWindow(GetDlgItem(hDlg, IDC_STC_DEVIDER), 0, pt.Y, rect.Right - rect.Left, 2, True);
        SetStatusbar(hDlg, lParam, wParam);
        SendDlgItemMessage(hApp, IDC_STATBAR, SB_SETTEXT, 0, Integer(Format(rsUser, [''])));
        SendDlgItemMessage(hApp, IDC_STATBAR, SB_SETTEXT, 1, Integer(Format(rsPW, [''])));
      end;
    WM_TIMER:
      begin
        // Animate Window icon
        hIcon := LoadIcon(HInstance, MAKEINTRESOURCE(idxico));
        SendMessage(hDlg, WM_SETICON, ICON_BIG, hIcon);
        SendMessage(hDlg, WM_SETICON, ICON_SMALL, hIcon);
        IconData.hIcon := hIcon;
        Shell_NotifyIcon(NIM_MODIFY, @IconData);
        if bUp then
        begin
          Inc(idxico);
          if idxico = 5 then
            bUp := False;
        end
        else
        begin
          Dec(idxico);
          if idxico = 1 then
            bUp := True;
        end;
      end;
    WM_CLOSE:
      begin
        Terminate := True;
        Shell_NotifyIcon(NIM_DELETE, @IconData);
        EndDialog(hDlg, 0);
      end;
    WM_SYSCOMMAND:
      begin
        case wParam of
          SC_MINIMIZE:
            begin
              AnimateWindow(hDlg, 500, AW_BLEND or AW_HIDE);
              SetWindowLong(hDlg, GWL_STYLE, GetWindowLong(hDlg, GWL_STYLE) or WS_ICONIC);
              Shell_NotifyIcon(NIM_ADD, @IconData);
            end;
        end;
        result := False;
      end;
    TNA_MSG:
      begin
        if lParam = WM_LBUTTONUP then
        begin
          SetWindowLong(hDlg, GWL_STYLE, GetWindowLong(hDlg, GWL_STYLE) and not WS_ICONIC);
          ShowWindow(hDlg, SW_SHOWNORMAL);
          Shell_NotifyIcon(NIM_DELETE, @IconData);
        end;
      end;
    WM_COMMAND:
      begin
        { accel for closing the dialog with ESC }
        if wParam = ID_CANCEL then
          SendMessage(hDlg, WM_CLOSE, 0, 0);
        { button and menu clicks }
        if hiword(wParam) = EN_CHANGE then
        begin
          case loword(wParam) of
            IDC_EDT_FILE:
              begin
                GetDlgItemText(hDlg, IDC_EDT_FILE, Buffer, sizeof(Buffer));
                GetDlgItemtext(hDlg, IDC_STC_USER, Buffer, sizeof(Buffer));
                EnableControl(hDlg, IDC_BTN_GO, True and (GetCheck(hDlg, IDC_OPT_FILE)) and (string(Buffer) <> ''));
              end;
          end;
        end;
        if hiword(wParam) = BN_CLICKED then
        begin
          case LoWord(wParam) of
            IDC_BTN_ABOUT:
              begin
                TAboutWnd.MsgBox(hDlg, 1);
              end;
            IDC_OPT_BF, IDC_OPT_FILE:
              begin
                EnableControl(hDlg, IDC_EDT_CHARS, not GetCheck(hDlg, IDC_OPT_FILE));
                EnableControl(hDlg, IDC_EDT_MINLEN, not GetCheck(hDlg, IDC_OPT_FILE));
                EnableControl(hDlg, IDC_UD_MINLEN, not GetCheck(hDlg, IDC_OPT_FILE));
                EnableControl(hDlg, IDC_EDT_MAXLEN, not GetCheck(hDlg, IDC_OPT_FILE));
                EnableControl(hDlg, IDC_UD_MAXLEN, not GetCheck(hDlg, IDC_OPT_FILE));
                EnableControl(hDlg, IDC_EDT_FILE, GetCheck(hDlg, IDC_OPT_FILE));
                EnableControl(hDlg, IDC_BTN_FILE, GetCheck(hDlg, IDC_OPT_FILE));
              end;
            IDC_BTN_FILE:
              begin
                s := OpenFile(hDlg, '');
                if s <> '' then
                begin
                  SetDlgItemText(hDlg, IDC_EDT_FILE, PChar(s));
                  CountLines := CountTextFileLines(s);
                end;
              end;
            IDC_BTN_GO:
              begin
                // GUI stuff
                SetTimer(hDlg, idTimer, 400, nil);
                EnableControl(hDlg, IDC_BTN_CANCEL, True);
                EnableControl(hDlg, IDC_BTN_GO, False);
                EnableControl(hDlg, IDC_LST_USER, False);
                SetDlgItemText(hDlg, IDC_EDT_PW, nil);
                if GetCheck(hDlg, IDC_OPT_BF) then // BruteForce
                begin
                  MinLen := GetDlgItemInt(hDlg, IDC_EDT_MINLEN, bTrans, False);
                  MaxLen := GetDlgItemInt(hDlg, IDC_EDT_MAXLEN, bTrans, False);
                    // Threadparams
                  New(BFThreadParams);
                  BFThreadParams.User := User;
                  GetDlgItemText(hDlg, IDC_EDT_CHARS, Buffer, sizeof(Buffer));
                  BFThreadParams.Chars := string(Buffer);
                  BFThreadParams.MinLen := MinLen;
                  BFThreadParams.MaxLen := MaxLen;
                    //Start thread
                  CloseHandle(BeginThread(nil, 0, @BruteForceThreadManager, BFThreadParams, 0, ThreadID));
                end
                else // Dictionary
                begin
                  // Threadparams
                  New(DictThreadParams);
                  GetDlgItemText(hDlg, IDC_EDT_FILE, Buffer, sizeof(Buffer));
                  DictThreadParams.DictFile := string(Buffer);
                  //GetDlgItemText(hDlg, IDC_STC_USER, Buffer, sizeof(Buffer));
                  DictThreadParams.User := User;
                  //Start thread
                  CloseHandle(BeginThread(nil, 0, @DictThread, DictThreadParams, 0, ThreadID));
                end;
                SetFocus(GetDlgItem(hDlg, IDC_BTN_CANCEL));
                SendDlgItemMessage(hDlg, IDC_EDT_CHARS, EM_SETSEL, 0, 0);
              end;
            IDC_BTN_CANCEL:
              begin
                // GUI stuff
                KillTimer(hDlg, idTimer);
                hIcon := LoadIcon(HInstance, MAKEINTRESOURCE(1));
                SendMessage(hDlg, WM_SETICON, ICON_BIG, hIcon);
                SendMessage(hDlg, WM_SETICON, ICON_SMALL, hIcon);
                EnableControl(hDlg, IDC_BTN_CANCEL, False);
                EnableControl(hDlg, IDC_BTN_GO, True);
                EnableControl(hDlg, IDC_LST_USER, True);
                // Terminate thread
                Terminate := True;
                SetFocus(GetDlgItem(hDlg, IDC_BTN_GO));
                SendDlgItemMessage(hDlg, IDC_EDT_CHARS, EM_SETSEL, 0, 0);
              end;
          end;
        end;
      end;
    WM_NOTIFY:
      begin
        if PNMHdr(lParam).idFrom = IDC_LST_USER then
          case PNMHdr(lParam)^.code of
            // LV selection has changed, get selection
            LVN_ITEMCHANGED:
              begin
                lvi.iItem := SendDlgItemMessage(hApp, IDC_LST_USER, LVM_GETNEXTITEM, -1, LVNI_FOCUSED);
                lvi.iSubItem := 0;
                lvi.mask := LVIF_TEXT;
                lvi.pszText := Buffer;
                lvi.cchTextMax := 256;
                SendDlgItemMessage(hApp, IDC_LST_USER, LVM_GETITEM, 0, Integer(@lvi));
                User := string(Buffer);
                SendDlgItemMessage(hApp, IDC_STATBAR, SB_SETTEXT, 0, Integer(Format(rsUser, [@User[1]])));
                SetDlgItemText(hDlg, IDC_EDT_PW, nil);
                GetDlgItemText(hDlg, IDC_EDT_FILE, Buffer, sizeof(Buffer));
                EnableControl(hDlg, IDC_BTN_GO, True and (GetCheck(hDlg, IDC_OPT_FILE) or (GetCheck(hDlg, IDC_OPT_BF))
                  or (FileExists(string(Buffer)))));
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

