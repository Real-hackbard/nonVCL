program AudioPlayer;

uses
  windows, messages, CommCtrl, bass, CommDlg;


{$R 'resource.res'}
{$INCLUDE GUITools.inc}
{$INCLUDE AppTools.inc}
{$INCLUDE SysUtils.inc}
{$INCLUDE FileTools.inc}

const

  IDC_BTNABOUT = 101;
  IDC_TRACKER = 102;
  IDC_BTNSTART = 104;
  IDC_BTNPAUSE = 105;
  IDC_BTNSTOP = 106;
  IDC_BTNNEXT = 107;
  IDC_BTNPRIOR = 103;
  IDC_RDBCD = 110;
  IDC_RDBMP3 = 108;
  IDC_BTNOPEN = 109;
  IDC_CHKLOOP = 111;
  IDC_CHKPLAYLIST = 112;
  IDC_LSTPLAYLIST = 113;
  IDC_STCLBSEL = 114;
  IDC_GRBPLAYLIST = 115;
  IDC_BTNPLAYLIST = 116;
  IDC_STCTRACKTITLE = 118;
  IDC_STATUSBAR = 120;

  IDM_TOPMOST = 301;
  IDM_MINIMODUS = 302;

  IDM_ADD = 201;
  IDM_DEL = 202;
  IDM_CLEAR = 205;
  IDM_UP = 206;
  IDM_DOWN = 207;
  IDM_LOAD = 203;
  IDM_SAVE = 204;

  FontName = 'Tahoma';
  FontSize = -18;

const
  FILTER =
    'MP3 (*.mp3)'#0'*.mp3'#0'OGG Vorbis (*.ogg)'#0'*.ogg'#0'Wave (*.wav)'#0'*.wav'#0#0;

const
  APPNAME = 'Audio-Player';
  VER = '1.0';
  INFO_TEXT = APPNAME + ' ' + VER + #13#10 +
    'Copyright © Your Name' + #13#10#13#10 +
    'https://github.com';

type
  TFiles = array of string;

var
  hApp: Cardinal;
  bMiniModus: Boolean = FALSE;
  bCD, bPaused: Boolean;
  CDTrack: DWORD = 0;
  CDTrackLength, CDNumTracks: DWORD;
  StrFileLength: Cardinal;
  Filelist: TFiles;

  DL_Message: DWORD;
  DragListboxbuffer: array[0..MAX_PATH - 1] of Char;
  ItemIdxBeginDrag, ItemIdxEndDrag, ItemIdxDragging: Integer;
  IsDragging: Boolean = FALSE;

  whitebrush: HBRUSH = 0;
  WhiteLB: TLogBrush =
  (
    lbStyle: BS_SOLID;
    lbColor: $00FFFFFF;
    lbHatch: 0
    );

  blackbrush: HBRUSH = 0;
  BlackLB: TLogBrush =
  (
    lbStyle: BS_SOLID;
    lbColor: $000000;
    lbHatch: 0
    );

function FormatTime(t: Cardinal): string; forward;
procedure PlayStream(DisplayText: string; Track: DWORD); forward;

//////////////////////////// BASS Common ///////////////////////////////////////

{$INCLUDE BASSCommon.inc}

////////////////////////// CD-Session //////////////////////////////////////////

{$INCLUDE CDSession.inc}

//////////////////////// Stream-Session ////////////////////////////////////////

{$INCLUDE StreamSession.inc}

//////////////////////////// APP Common ////////////////////////////////////////

function SetWindowTopMost(hWnd: HWND; bTopMost: boolean): boolean;
(*
  Functionality:
    Sets the given window to stay always on top.
    [GENERIC]
*)
begin
  result := SetWindowPos(hWnd, HWND_NOTOPMOST + WORD(bTopMost), 0, 0, 0, 0,
    SWP_NOMOVE or SWP_NOSIZE or
    SWP_NOACTIVATE);
end;

function IsTopMost(hWnd: HWND): boolean;
(*
  Functionality:
    Checks wether the window is set to stay on top.
    [GENERIC]
*)
begin
  result := BOOL(GetWindowLong(hWnd, GWL_EXSTYLE) and WS_EX_TOPMOST);
end;

function SetMiniModus(bModus: Boolean): Boolean;
begin
  if bModus then
    SetWindowPos(hApp, 0, 0, 0, 332, 260, SWP_NOMOVE)
  else
    SetWindowPos(hApp, 0, 0, 0, 332, 465, SWP_NOMOVE);
  result := bModus;
end;

function FormatTime(t: Cardinal): string;
begin
  t := t div 1000; // -> seconds
  result := IntToStr(t mod 60);
  case t mod 60 < 10 of
    true: result := '0' + result;
  end;
  t := t div 60; //minutes
  result := IntToStr(t mod 60) + ':' + result;
  case t mod 60 < 10 of
    true: result := '0' + result;
  end;
  t := t div 60; //hours
  result := IntToStr(t mod 24) + ':' + result;
  case t mod 60 < 10 of
    true: result := '0' + result;
  end;
end;

const
{$EXTERNALSYM OPENFILENAME_SIZE_VERSION_400A}
  OPENFILENAME_SIZE_VERSION_400A = sizeof(TOpenFileNameA) -
    sizeof(pointer) - (2 * sizeof(dword));
{$EXTERNALSYM OPENFILENAME_SIZE_VERSION_400W}
  OPENFILENAME_SIZE_VERSION_400W = sizeof(TOpenFileNameW) -
    sizeof(pointer) - (2 * sizeof(dword));
{$EXTERNALSYM OPENFILENAME_SIZE_VERSION_400}
  OPENFILENAME_SIZE_VERSION_400 = OPENFILENAME_SIZE_VERSION_400A;

function IsNT5OrHigher: Boolean;
var
  ovi: TOSVERSIONINFO;
begin
  ZeroMemory(@ovi, sizeof(TOSVERSIONINFO));
  ovi.dwOSVersionInfoSize := SizeOf(TOSVERSIONINFO);
  GetVersionEx(ovi);
  if (ovi.dwPlatformId = VER_PLATFORM_WIN32_NT) and (ovi.dwMajorVersion >= 5)
    then
    result := TRUE
  else
    result := FALSE;
end;

function OpenFile(flags: DWORD): string;
var
  ofn: TOpenFilename;
  Buffer: array[0..4096] of Char;
  i: Integer;
  szWork: PChar;
begin
  setlength(Filelist, 0);
  result := '';
  ZeroMemory(@Buffer[0], sizeof(Buffer));
  ZeroMemory(@ofn, sizeof(TOpenFilename));
  if IsNt5OrHigher then
    ofn.lStructSize := sizeof(TOpenFilename)
  else
    ofn.lStructSize := OPENFILENAME_SIZE_VERSION_400;
  ofn.hWndOwner := hApp;
  ofn.hInstance := hInstance;
  ofn.lpstrFilter := FILTER;
  ofn.lpstrFile := @Buffer[0];
  ofn.nMaxFile := sizeof(Buffer);
  ofn.Flags := OFN_EXPLORER or OFN_HIDEREADONLY {or OFN_FILEMUSTEXIST} or flags;
  { Datei-Öffnen-Dialog aufrufen }
  if GetOpenFileName(ofn) then
  begin
    if flags = 0 then { no multiselection }
      result := ofn.lpstrFile
    else
    begin
      i := 0;
      setlength(Filelist, 1);
      szWork := buffer;
      Filelist[0] := string(szWork);
      while szWork[0] <> #0 do
      begin
        inc(i);
        setlength(Filelist, i + 1);
        szWork := PChar(@szWork[lstrlen(szWork) + 1]);
        Filelist[i] := string(szWork);
      end;
      setlength(Filelist, i);
    end;
  end;
end;

procedure EnableCtrls(btnPrior, btnStart, btnPause, btnStop, btnNext, Tracker:
  Boolean);
begin
  EnableWindow(GetDlgItem(hApp, IDC_BTNPRIOR), btnPrior);
  EnableWindow(GetDlgItem(hApp, IDC_BTNSTART), btnStart);
  EnableWindow(GetDlgItem(hApp, IDC_BTNPAUSE), btnPause);
  EnableWindow(GetDlgItem(hApp, IDC_BTNSTOP), btnStop);
  EnableWindow(GetDlgItem(hApp, IDC_BTNNEXT), btnNext);
  EnableWindow(GetDlgItem(hApp, IDC_BTNNEXT), btnNext);
  EnableWindow(GetDlgItem(hApp, IDC_TRACKER), Tracker);
end;

procedure ShowPopup(x, y: DWORD);
var
  hMenu, hPopupMenu: Cardinal;
begin
  hMenu := LoadMenu(hInstance, MAKEINTRESOURCE(200));
  hPopupMenu := GetSubmenu(hMenu, 0);
  TrackPopupMenu(hPopupMenu, TPM_LEFTALIGN or TPM_HORPOSANIMATION, x, y, 0,
    hApp, nil);
end;

procedure PlayStream(DisplayText: string; Track: DWORD);
var
  s: string;
begin
  s := CutPathname(ChangeFileExt(Filename, ''));
  SetWindowText(hApp, @s[1]);
  s := FormatTime(Round(BASS_ChannelBytes2Seconds(hFileStream, StrFileLength)) *
    1000);
  SendDlgItemMessage(hApp, IDC_STATUSBAR, SB_SETTEXT, 0, Integer(@s[1]));
  s := 'BitRate: ' + IntToStr(BASSGetBitRate(hFileStream)) + ' KB/s';
  SendDlgItemMessage(hApp, IDC_STATUSBAR, SB_SETTEXT, 1, Integer(@s[1]));
  s := BASSGetMode(hFileStream);
  SendDlgItemMessage(hApp, IDC_STATUSBAR, SB_SETTEXT, 2, Integer(@s[1]));
  s := 'Samplerate: ' + IntToStr(BASSGetFreq(hFileStream)) + ' kHz';
  SendDlgItemMessage(hApp, IDC_STATUSBAR, SB_SETTEXT, 3, Integer(@s[1]));
  SendDlgItemMessage(hApp, IDC_TRACKER, TBM_SETRANGEMAX, 0, StrFileLength);
  if STRPlay() then
  begin
    EnableCtrls(FALSE, FALSE, TRUE, TRUE, FALSE, TRUE);
    SetDlgItemText(hApp, IDC_STCTRACKTITLE, @DisplayText[1]);
  end;
end;

function dlgfunc(hDlg: hWnd; uMsg: dword; wParam: wParam; lParam: lParam): bool;
  stdcall;
var
  hSysMenu: Cardinal;
  MyFont: HFONT;
  s: string;
  PanelWidth: array[0..3] of Integer;
  i, idx: Integer;
  buffer: array[0..MAX_PATH - 1] of Char;
  pt: TPoint;
  rect: TRECT;
begin
  result := true;
  case uMsg of
    WM_INITDIALOG:
      begin
        hApp := hDlg;
        { icon }
        if SendMessage(hDlg, WM_SETICON, ICON_SMALL, Integer(LoadIcon(hInstance,
          MAKEINTRESOURCE(1)))) = 0 then
          SendMessage(hDlg, WM_SETICON, ICON_BIG, Integer(LoadIcon(hInstance,
            MAKEINTRESOURCE(1))));
        { Add items tothe systemmenu }
        hSysMenu := GetSystemMenu(hDlg, False);
        AppendMenu(hSysMenu, MF_SEPARATOR, 0, nil);
        AppendMenu(hSysMenu, MF_BYPOSITION, IDM_MINIMODUS, '&Mini-Modus');
        AppendMenu(hSysMenu, MF_BYPOSITION, IDM_TOPMOST,
          'Always in the foreground');
        { font }
        MyFont := CreateFont(FontSize, 0, 0, 0, 900, 0, 0, 0, ANSI_CHARSET,
          OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
          DEFAULT_PITCH, FontName);
        if MyFont <> 0 then
          SendDlgItemMessage(hDlg, 999, WM_SETFONT, Integer(MyFont),
            Integer(true));
        SetWindowLong(GetDlgItem(hDlg, IDC_STCTRACKTITLE), GWL_STYLE,
          GetWindowLong(GetDlgItem(hdlg, IDC_STCTRACKTITLE), GWL_STYLE) or
          SS_WORDELLIPSIS or SS_NOTIFY);
        { set windowcaption and white banner caption }
        s := APPNAME + ' ' + VER;
        SetWindowText(hDlg, pointer(s));
        SetDlgItemText(hDlg, 999, pointer(s));
        { font for title and track static }
        MyFont := CreateFont(-8, 0, 0, 0, 700, 0, 0, 0, ANSI_CHARSET,
          OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
          DEFAULT_PITCH, 'MS Sans Serif');
        if MyFont <> 0 then
          SendDlgItemMessage(hDlg, IDC_STCTRACKTITLE, WM_SETFONT,
            Integer(MyFont),
            Integer(true));
        { statuswindow }
        CreateStatusWindow(WS_VISIBLE or WS_CHILD or SBT_TOOLTIPS, nil, hDlg,
          IDC_STATUSBAR);
        PanelWidth[0] := 55;
        PanelWidth[1] := 150;
        PanelWidth[2] := 200;
        PanelWidth[3] := 330;
        SendMessage(GetDlgItem(hDlg, IDC_STATUSBAR), SB_SETPARTS, 4,
          Integer(@PanelWidth));
        { check the mp3 radio button }
        CheckDlgButton(hDlg, IDC_RDBMP3, BST_CHECKED);
        { listbox -> drag listbox }
        MakeDragList(GetDlgItem(hDlg, IDC_LSTPLAYLIST));
        DL_Message := RegisterWindowMessage(DRAGLISTMSGSTRING);
        SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_SETHORIZONTALEXTENT, 600,
          0);
        { add tooltips to the controlls }
        CreateToolTips(hDlg);
        AddToolTip(hDlg, IDC_BTNABOUT, @ti, 'Information about the program');
        AddToolTip(hDlg, IDC_TRACKER, @ti, 'current position in the title');
        AddToolTip(hDlg, IDC_BTNPRIOR, @ti, 'Title back');
        AddToolTip(hDlg, IDC_BTNSTART, @ti, 'Play title');
        AddToolTip(hDlg, IDC_BTNPAUSE, @ti, 'Pause');
        AddToolTip(hDlg, IDC_BTNSTOP, @ti, 'Stop playback');
        AddToolTip(hDlg, IDC_BTNNEXT, @ti, 'next title');
        AddToolTip(hDlg, IDC_RDBCD, @ti, 'Play CD');
        AddToolTip(hDlg, IDC_RDBMP3, @ti, 'Play MP3 or Wave');
        AddToolTip(hDlg, IDC_BTNOPEN, @ti, 'Open MP3 or Wave');
        AddToolTip(hDlg, IDC_CHKPLAYLIST, @ti, 'Activate playlist');
        AddToolTip(hDlg, IDC_BTNPLAYLIST, @ti, 'Playlist menu');
        AddToolTip(hDlg, IDC_STCTRACKTITLE, @ti, 'Double-click for file information');

        BASSInit();
        EnableCtrls(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE);
        SendDlgItemMessage(hApp, IDC_TRACKER, TBM_SETPOS, Integer(TRUE), 0);
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
          IDC_STCTRACKTITLE:
            begin
              SetTextColor(wParam, RGB(176, 176, 0));
              blackbrush := CreateBrushIndirect(BlackLB);
              SetBkColor(wParam, BlackLB.lbColor);
              result := BOOL(blackbrush);
            end;
        else
          result := FALSE;
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
        MoveWindow(GetDlgItem(hDlg, IDC_STATUSBAR), LOWORD(lParam),
          HIWORD(lParam), 0, 0, true);
        SetWindowPos(GetDlgItem(hDlg, 999), HWND_BOTTOM, 0, 0, loword(lparam),
          75, 0);
        SetWindowPos(GetDlgItem(hDlg, 101), GetDlgItem(hDlg, 999), loword(lParam)
          - 47, 7, 40, 22, 0);
        SetWindowPos(GetDlgItem(hDlg, IDC_CHKPLAYLIST), GetDlgItem(hDlg,
          IDC_GRBPLAYLIST), 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
      end;
    WM_CLOSE:
      begin
        ShowWindow(hDlg, SW_HIDE);
        if bCD then
        begin
          CDStopTrack();
          CDEndSession();
          BASS_CDFree();
        end;
        BASS_Free();
        EndDialog(hDlg, 0);
      end;
    WM_SYSCOMMAND: { systemmenu }
      begin
        case wParam of
          IDM_TOPMOST: SetWindowTopMost(hDlg, not IsTopMost(hDlg));
          IDM_MINIMODUS: bMiniModus := SetMiniModus(not bMiniModus);
        else
          result := FALSE;
        end;
      end;
    WM_INITMENUPOPUP: { systemmenu is about to open, set the Topmost state }
      begin
        if BOOL(HIWORD(lParam)) then
          if IsTopMost(hDlg) then
            CheckMenuItem(GetSystemMenu(hDlg, False), IDM_TOPMOST, MF_CHECKED)
          else
            CheckMenuItem(GetSystemMenu(hDlg, False), IDM_TOPMOST,
              MF_UNCHECKED);
        if bMiniModus then
          CheckMenuItem(GetSystemMenu(hDlg, False), IDM_MINIMODUS, MF_CHECKED)
        else
          CheckMenuItem(GetSystemMenu(hDlg, False), IDM_MINIMODUS, MF_UNCHECKED)
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
            IDC_BTNABOUT: MyMessageBox(hDlg, APPNAME, INFO_TEXT, 2);
            IDC_BTNPRIOR:
              begin
                if bCD then
                begin
                  Dec(CDTrack);
                  CDTrackLength := CDPlayTrack(CDTrack);
                  if CDTrackLength > 0 then
                  begin
                    EnableCtrls(FALSE, TRUE, TRUE, TRUE, TRUE, TRUE);
                    SendDlgItemMessage(hDlg, IDC_TRACKER, TBM_SETRANGEMAX,
                      Integer(TRUE), CDTrackLength);
                    s := '[ ' + IntToStr(CDTrack) + ' / ' +
                      IntToStr(CDNumTracks) + ' ]';
                    SetDlgItemText(hDlg, IDC_STCTRACKTITLE, @s[1]);
                  end;
                end;
              end;
            IDC_BTNSTART:
              begin
                if bCD then
                begin
                  CDTrackLength := CDPlayTrack(CDTrack);
                  if CDTrackLength > 0 then
                  begin
                    EnableCtrls(FALSE, TRUE, TRUE, TRUE, FALSE, TRUE);
                    SendDlgItemMessage(hDlg, IDC_TRACKER, TBM_SETRANGEMAX,
                      Integer(TRUE), CDTrackLength);
                  end;
                end
                else
                begin
                  if not bPaused then
                  begin
                    if length(Filename) <> 0 then
                    begin
                      StrFileLength := STROpen();
                      if StrFileLength > 0 then
                      begin
                        if IsDlgButtonChecked(hDlg, IDC_CHKPLAYLIST) =
                          BST_CHECKED then
                          s := '[ ' + IntToStr(StrTrack + 1) + ' / ' +
                            IntToStr(SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST,
                            LB_GETCOUNT, 0, 0)) + ' ] ' +
                              ChangeFileExt(CutPathname(Filename), '')
                        else
                          s := '[ - / - ] ' +
                            ChangeFileExt(CutPathname(Filename), '');
                        PlayStream(s, StrTrack);
                      end;
                    end;
                  end
                  else
                  begin
                    BASS_ChannelResume(hFileStream);
                    { set global flag }
                    bPaused := FALSE;
                    EnableCtrls(FALSE, FALSE, TRUE, TRUE, FALSE, TRUE);
                  end;
                end;
              end;
            IDC_BTNPAUSE:
              begin
                if bCD then
                begin
                  if CDPause() then
                    EnableCtrls(FALSE, TRUE, FALSE, TRUE, FALSE, TRUE);
                end
                else
                begin
                  if STRPause() then
                    EnableCtrls(FALSE, TRUE, FALSE, TRUE, FALSE, FALSE);
                end;
              end;
            IDC_BTNSTOP:
              begin
                if bCD then
                begin
                  CDStopTrack();
                  EnableCtrls(FALSE, TRUE, FALSE, FALSE, FALSE, FALSE);
                  SetFocus(GetDlgItem(hDlg, IDC_BTNSTART));
                  SendDlgItemMessage(hDlg, IDC_TRACKER, TBM_SETPOS,
                    Integer(TRUE), 0);
                end
                else
                begin
                  if StrStop() then
                  begin
                    EnableCtrls(FALSE, TRUE, FALSE, FALSE, FALSE, FALSE);
                    SetFocus(GetDlgItem(hDlg, IDC_BTNSTART));
                    SendDlgItemMessage(hDlg, IDC_TRACKER, TBM_SETPOS,
                      Integer(TRUE), 0);
                  end;
                end;
              end;
            IDC_BTNNEXT:
              begin
                if bCD then
                begin
                  Inc(CDTrack);
                  CDTrackLength := CDPlayTrack(CDTrack);
                  if CDTrackLength > 0 then
                  begin
                    EnableCtrls(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE);
                    SendDlgItemMessage(hDlg, IDC_TRACKER, TBM_SETRANGEMAX,
                      Integer(TRUE), CDTrackLength);
                    s := '[ ' + IntToStr(CDTrack) + ' / ' +
                      IntToStr(CDNumTracks) + ' ]';
                    SetDlgItemText(hDlg, IDC_STCTRACKTITLE, @s[1]);
                  end;
                end;
              end;
            IDC_RDBCD:
              begin
                STREndSession;
                Filename := '';
                SendDlgItemMessage(hDlg, IDC_STATUSBAR, SB_SETTEXT, 0,
                  Integer(nil));
                SendDlgItemMessage(hDlg, IDC_STATUSBAR, SB_SETTEXT, 1,
                  Integer(nil));
                SendDlgItemMessage(hDlg, IDC_STATUSBAR, SB_SETTEXT, 2,
                  Integer(nil));
                SendDlgItemMessage(hDlg, IDC_STATUSBAR, SB_SETTEXT, 3,
                  Integer(nil));
                s := APPNAME + ' ' + VER;
                SetWindowText(hApp, pointer(s));
                SetDlgItemText(hApp, 999, pointer(s));
                CDTrack := 1;
                if CDStartSession(CDTracklength, CDNumTracks) then
                begin
                  if CDPlayTrack(1) > 0 then
                  begin
                    EnableCtrls(FALSE, TRUE, TRUE, TRUE, FALSE, TRUE);
                    EnableWindow(GetDlgItem(hDlg, IDC_BTNOPEN), FALSE);
                    SendDlgItemMessage(hDlg, IDC_TRACKER, TBM_SETRANGEMAX,
                      Integer(TRUE), CDTrackLength);
                    s := '[ ' + IntToStr(CDTrack) + ' / ' +
                      IntToStr(CDNumTracks) + ' ]';
                    SetDlgItemText(hDlg, IDC_STCTRACKTITLE, @s[1]);
                  end
                end
                else
                begin
                  EnableCtrls(FALSE, TRUE, FALSE, FALSE, FALSE, FALSE);
                  CheckDlgButton(hDlg, IDC_RDBCD, BST_UNCHECKED);
                  CheckDlgButton(hDlg, IDC_RDBMP3, BST_CHECKED);
                  SendDlgItemMessage(hDlg, IDC_TRACKER, TBM_SETPOS,
                    Integer(TRUE), 0);
                  SetFocus(GetDlgItem(hDlg, IDC_RDBMP3));
                end;
              end;
            IDC_RDBMP3:
              begin
                CDEndSession();
                EnableCtrls(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE);
                if IsDlgButtonChecked(hDlg, IDC_CHKPLAYLIST) = BST_CHECKED then
                  EnableWindow(GetDlgItem(hApp, IDC_BTNOPEN), FALSE)
                else
                  EnableWindow(GetDlgItem(hApp, IDC_BTNOPEN), TRUE);
                EnableCtrls(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE);
                SendDlgItemMessage(hApp, IDC_TRACKER, TBM_SETPOS, Integer(TRUE),
                  0);
                SendDlgItemMessage(hDlg, IDC_STATUSBAR, SB_SETTEXT, 0,
                  Integer(nil));
                SendDlgItemMessage(hDlg, IDC_STATUSBAR, SB_SETTEXT, 1,
                  Integer(nil));
                SendDlgItemMessage(hDlg, IDC_STATUSBAR, SB_SETTEXT, 2,
                  Integer(nil));
                SendDlgItemMessage(hDlg, IDC_STATUSBAR, SB_SETTEXT, 4,
                  Integer(nil));
                SetDlgItemText(hDlg, IDC_STCTRACKTITLE, nil);
              end;
            IDC_BTNOPEN:
              begin
                Filename := OpenFile(0);
                if length(Filename) <> 0 then
                begin
                  StrFileLength := STROpen();
                  if StrFileLength > 0 then
                  begin
                    s := '[ -/- ] ' + ChangeFileExt(CutPathname(Filename), '');
                    PlayStream(s, StrTrack);
                  end;
                end;
              end;
            IDC_CHKPLAYLIST:
              begin
                EnableWindow(GetDlgItem(hDlg, IDC_LSTPLAYLIST),
                  (IsDlgButtonChecked(hDlg, IDC_CHKPLAYLIST) = BST_CHECKED));
                EnableWindow(GetDlgItem(hDlg, IDC_BTNPLAYLIST),
                  (IsDlgButtonChecked(hDlg, IDC_CHKPLAYLIST) = BST_CHECKED));
                EnableWindow(GetDlgItem(hDlg, IDC_BTNopen), not
                  (IsDlgButtonChecked(hDlg, IDC_CHKPLAYLIST) = BST_CHECKED));
              end;
            IDC_BTNPLAYLIST:
              begin
                GetWindowRect(GetDlgItem(hDlg, IDC_BTNPLAYLIST), rect);
                ShowPopup(rect.Left, rect.Bottom);
              end;
            IDM_ADD:
              begin
                OpenFile(OFN_ALLOWMULTISELECT);
                if length(Filelist) > 0 then
                begin
                  if length(Filelist) = 1 then
                    SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_ADDSTRING, 0,
                      Integer(@Filelist[0][1]));
                  s := Filelist[0];
                  for i := 1 to length(Filelist) - 1 do
                  begin
                    s := Filelist[0] + '\' + Filelist[i];
                    SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_ADDSTRING, 0,
                      Integer(@s[1]));
                  end;
                  EnableWindow(GetDlgItem(hDlg, IDC_BTNSTART), TRUE);
                  Filename := STRGetFileFromLB(0);
                  StrTrack := 0;
                  s := 'Titel: ' + IntToStr(SendDlgItemMessage(hDlg,
                    IDC_LSTPLAYLIST, LB_GETCOUNT, 0, 0));
                  SendDlgItemMessage(hDlg, IDC_STATUSBAR, SB_SETTEXT, 0,
                    Integer(@s[1]));
                end;
              end;
            IDM_DEL:
              begin
                idx := SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_GETCURSEL,
                  0, 0);
                if idx <> LB_ERR then
                begin
                  SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_DELETESTRING,
                    idx, 0);
                  s := 'Titel: ' + IntToStr(StrTrack + 1) + '/' +
                    IntToStr(SendDlgItemMessage(hApp, IDC_LSTPLAYLIST,
                    LB_GETCOUNT, 0, 0));
                  SendDlgItemMessage(hDlg, IDC_STATUSBAR, SB_SETTEXT, 0,
                    Integer(@(s)[1]));
                end;
              end;
            IDM_CLEAR:
              begin
                SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_RESETCONTENT, 0,
                  0);
                SetDlgItemText(hDlg, IDC_STCLBSEL, nil);
                SendDlgItemMessage(hDlg, IDC_STATUSBAR, SB_SETTEXT, 0,
                  Integer(nil));
                SendDlgItemMessage(hDlg, IDC_STATUSBAR, SB_SETTEXT, 1,
                  Integer(nil));
                SendDlgItemMessage(hDlg, IDC_STATUSBAR, SB_SETTEXT, 2,
                  Integer(nil));
              end;
            IDM_UP:
              begin
                idx := SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_GETCURSEL,
                  0, 0);
                if idx = 0 then
                  exit;
                SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_GETTEXT, idx,
                  Integer(@buffer));
                SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_INSERTSTRING, idx -
                  1, Integer(@buffer));
                SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_DELETESTRING, idx +
                  1, 0);
                SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_SETCURSEL, idx - 1,
                  0);
              end;
            IDM_DOWN:
              begin
                idx := SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_GETCURSEL,
                  0, 0);
                if idx = SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_GETCOUNT,
                  0, 0) - 1 then
                  exit;
                SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_GETTEXT, idx,
                  Integer(@buffer));
                SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_INSERTSTRING, idx +
                  2, Integer(@buffer));
                SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_DELETESTRING, idx,
                  0);
                SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_SETCURSEL, idx + 1,
                  0);
              end;
          end;
        end;
        if hiword(wParam) = STN_DBLCLK then
        begin
          case loword(wParam) of
            IDC_STCTRACKTITLE:
              begin
                if length(Filename) <> 0 then
                begin
                  s := 'Name: ' + Filename + #13#10;
                  s := s + 'Filesize: ' + IntToStr(GetFileSize(@Filename[1])
                    div 1024) + ' KB' + #13#10;
                  s := s + 'Length: ' +
                    FormatTime(Round(BASS_ChannelBytes2Seconds(hFileStream,
                    StrFileLength)) * 1000) + ' [hh:mm:ss]' + #13#10;
                  s := s + 'BitRate: ' + IntToStr(BASSGetBitRate(hFileStream)) +
                    ' KB/s' + #13#10;
                  s := s + 'Mode: ' + BASSGetMode(hFileStream) + #13#10;
                  s := s + 'Samplerate: ' + IntToStr(BASSGetFreq(hFileStream)) +
                    ' kHz';
                end
                else
                  s := 'No title information available.';
                MessageBox(hDlg, @s[1], 'Title information', MB_ICONINFORMATION);
              end;
          end;
        end;
        if hiword(wParam) = LBN_SELCHANGE then
        begin
          case loword(wParam) of
            IDC_LSTPLAYLIST:
              begin
                if SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_GETCOUNT, 0, 0)
                  = 0 then
                  exit;
                idx := SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_GETCURSEL,
                  0, 0);
                SendDlgItemMessage(hApp, IDC_LSTPLAYLIST, LB_GETTEXT, idx,
                  Integer(@buffer));
                s := CutPathname(string(buffer));
                SetDlgItemText(hDlg, IDC_STCLBSEL, @s[1]);
              end;
          end;
        end;
        if hiword(wParam) = LBN_DBLCLK then
        begin
          case loword(wParam) of
            IDC_LSTPLAYLIST:
              begin
                if SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_GETCOUNT, 0, 0)
                  > 0 then
                begin
                  idx := SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_GETCURSEL,
                    0, 0);
                  Filename := STRGetFileFromLB(idx);
                  StrTrack := idx;
                  if length(Filename) <> 0 then
                  begin
                    StrFileLength := STROpen();
                    if StrFileLength > 0 then
                    begin
                      s := '[ ' + IntToStr(StrTrack + 1) + ' / ' +
                        IntToStr(SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST,
                        LB_GETCOUNT, 0, 0)) + ' ] ' +
                          ChangeFileExt(CutPathname(Filename), '');
                      PlayStream(s, StrTrack);
                    end;
                  end;
                end;
              end;
          end;
        end;
      end;
    WM_HSCROLL:
      begin
        case LoWord(wParam) of
          TB_THUMBTRACK, // pulling the "slider"
            TB_TOP, // Pos1
            TB_BOTTOM, // End
            TB_PAGEDOWN, // Clicked down the image and into the bar.
            TB_PAGEUP: // Image clicked on & in the bar
            begin
              if bCD then
                BASSSetTrackPos(CDChannel, SendDlgItemMessage(hDlg, IDC_TRACKER,
                  TBM_GETPOS, 0, 0))
              else
                BASSSetTrackPos(hFileStream, SendDlgItemMessage(hDlg,
                  IDC_TRACKER, TBM_GETPOS, 0, 0));
            end;
        end;
      end;
    WM_CONTEXTMENU:
      begin
        if IsDlgButtonChecked(hDlg, IDC_CHKPLAYLIST) = BST_CHECKED then
        begin
          GetCursorPos(pt);
          GetWindowRect(GetDlgItem(hDlg, IDC_LSTPLAYLIST), rect);
          if PtInRect(rect, pt) then
            ShowPopup(pt.X, pt.Y);
        end;
      end;
    WM_TIMER:
      begin
        case wParam of
          IDC_CDTIMER: CDTimerProc();
          IDC_STRTIMER: STRTimerproc();
        end;
      end;
  else
    result := false;
    if DL_MESSAGE <> 0 then
      if uMsg = DL_MESSAGE then
        case PDRAGLISTINFO(lParam)^.uNotification of
          DL_BEGINDRAG: { received when an item is selected }
            begin
              { get the ItemIndex of the item to bedragged and save it}
              ItemIdxBeginDrag := LBItemFromPt(GetDlgItem(hDlg,
                IDC_LSTPLAYLIST), PDRAGLISTINFO(lParam)^.ptCursor, TRUE);
              IsDragging := FALSE;
              { return the message result explicitly, otherwise we would not recieve DL_DRAGGING }
              SetWindowLong(hDlg, DWL_MSGRESULT, Integer(TRUE));
              Result := True;
            end;
          DL_DRAGGING: { received while dragging }
            begin
              { get the current item under the cursor }
              ItemIdxDragging := LBItemFromPt(GetDlgItem(hDlg, IDC_LSTPLAYLIST),
                PDRAGLISTINFO(lParam)^.ptCursor, TRUE);
              { draw a small arrow to show where the item is being inserted }
              DrawInsert(hDlg, PDRAGLISTINFO(lParam)^.hWnd, ItemIdxDragging);
              { user started dragging }
              IsDragging := TRUE;
            end;
          DL_CANCELDRAG: { user cancel dragging by pressing ESCAPE }
            begin
              { remove insert icon }
              DrawInsert(hDlg, PDRAGLISTINFO(lParam)^.hWnd, -1);
              IsDragging := FALSE;
            end;
          DL_DROPPED: { user finished dragging and dropped the item }
            if IsDragging then { user has started dragging }
            begin
              { where is the cursor? }
              ItemIdxEndDrag := LBItemFromPt(GetDlgItem(hDlg, IDC_LSTPLAYLIST),
                PDRAGLISTINFO(lParam)^.ptCursor, TRUE);
              { get the itemtext for old item }
              SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_GETTEXT,
                ItemIdxBeginDrag, Integer(@DragListboxBuffer));

              { Items werden IMMER vor dem Item eingefügt, über dem der Cursor ist. Siehe
                auch Insert-Icon. Kannst du in allen Produkten so sehen kenne keins wo es
               anders ist! }

              { adjust item index - index of ItemIdxEndDrag might change if a pre-
                ceeding item has been deleted. We have to handle this! }
              if ItemIdxBeginDrag < ItemIdxEndDrag then
                dec(ItemIdxEndDrag);
              { delete the old item }
              SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_DELETESTRING,
                ItemIdxBeginDrag, 0);
              { insert the old item at the new position }
              SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_INSERTSTRING,
                ItemIdxEndDrag, Integer(@DragListboxBuffer));
              { remove insert icon }
              DrawInsert(hDlg, PDRAGLISTINFO(lParam)^.hWnd, -1);
              SendDlgItemMessage(hDlg, IDC_LSTPLAYLIST, LB_SETCURSEL,
                ItemIdxeNDDrag, 0);
            end;
        end;
  end;
end;

begin
  { tooltips, drag listbox }
  InitCommonControls;

  DialogBox(hInstance, MAKEINTRESOURCE(100), 0, @dlgfunc);
end.

