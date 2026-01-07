const
  IDC_STRTIMER = 202;

var
  Filename: string;
  hFileStream: HSTREAM;
  hSTRTimer: Cardinal;
  StrTrack: Integer = 0; { Listbox index of current playing title }
  STRLoop: Boolean = FALSE;
  { forward declarations }
procedure StrEndSession; forward;
function StrPlay: Boolean; forward;
function StrStop: Boolean; forward;
function StrOpen: Cardinal; forward;
procedure StrTimerProc; forward;
function STRGetFileFromLB(idx: DWORD): string; forward;


procedure STRTimerProc;
var
  TrackPos: Int64;
  buffer: array[0..MAX_PATH - 1] of Char;
  s: string;
begin
  { adjust trackbar }
  TrackPos := BASS_ChannelGetPosition(hFileStream);
  SendDlgItemMessage(hApp, IDC_TRACKER, TBM_SETPOS, Integer(TRUE), TrackPos);
  { loop stuff }
  STRLoop := (IsDlgButtonChecked(hApp, IDC_CHKLOOP) = BST_CHECKED);
  if (TrackPos = BASS_StreamGetLength(hFileStream)) and STRLoop then
  begin
    BASS_ChannelSetPosition(hFileStream, 0);
  end;
  { no loop but track reached its end }
  if (TrackPos = BASS_StreamGetLength(hFileStream)) and (not STRLoop) and (
    IsDlgButtonChecked(hApp, IDC_CHKPLAYLIST) = BST_UNCHECKED) then
  begin
    BASS_ChannelSetPosition(hFileStream, 0);
    EnableWindow(GetDlgItem(hApp, IDC_BTNSTART), TRUE);
    EnableWindow(GetDlgItem(hApp, IDC_BTNPAUSE), FALSE);
    EnableWindow(GetDlgItem(hApp, IDC_BTNSTOP), FALSE);
    EnableWindow(GetDlgItem(hApp, IDC_TRACKER), FALSE);
    SetFocus(GetDlgItem(hApp, IDC_BTNSTART));
    STRStop();
    KillTimer(hApp, IDC_STRTIMER);
  end;
  { we are playing a playlist }
  if IsDlgButtonChecked(hApp, IDC_CHKPLAYLIST) = BST_CHECKED then
  begin
    if (BASS_ChannelIsActive(hFileStream) = BASS_ACTIVE_STOPPED) and (StrTrack
      < SendDlgItemMessage(hApp, IDC_LSTPLAYLIST, LB_GETCOUNT, 0, 0) - 1) then
    begin
      Inc(StrTrack);
      Filename := STRGetFileFromLB(StrTrack);
      if length(Filename) <> 0 then
      begin
        StrFileLength := STROpen();
        if StrFileLength > 0 then
        begin
          SendDlgItemMessage(hApp, IDC_LSTPLAYLIST, LB_SETCURSEL, StrTrack, 0);
          SendDlgItemMessage(hApp, IDC_LSTPLAYLIST, LB_GETTEXT, StrTrack,
            Integer(@buffer));
          s := CutPathname(string(buffer));
          SetDlgItemText(hApp, IDC_STCLBSEL, @s[1]);
          Filename := s;
          s := '[ ' + IntToStr(StrTrack + 1) + ' / ' +
            IntToStr(SendDlgItemMessage(hApp, IDC_LSTPLAYLIST, LB_GETCOUNT, 0,
            0))+' ] ' +CutPathname(Filename);
          PlayStream(s, StrTrack);
        end;
      end;
    end;
  end;
end;

function STRPlay: Boolean;
begin
//  if not bPaused then
//  begin
    { reset everything }
    BASS_Stop();
    BASS_Start();
    hFileStream := 0;

    { we are playing a play list, get the name from the listbox }
    if IsDlgButtonChecked(hApp, IDC_CHKPLAYLIST) = BST_CHECKED then
      Filename := STRGetFileFromLB(StrTrack);
    { check the string }
    if length(Filename) = 0 then
    begin
      result := FALSE;
      exit;
    end;
    { create the stream }
    hFileStream := BASS_StreamCreateFile(FALSE, @Filename[1], 0, 0,
      BASS_MP3_SETPOS or BASS_STREAM_AUTOFREE);
    if not BASS_StreamPlay(hFileStream, FALSE, 0) then
    begin
      BASS_Error(BASS_ErrorGetCode(), 'Fehler beim Abspielen des Streams.');
      result := FALSE;
      exit;
    end;
    { start the timer }
    hSTRTimer := SetTimer(hApp, IDC_STRTIMER, 10, @STRTimerProc);
    result := TRUE;
//  end
//  else
//  begin
//    { resume }
//    BASS_ChannelResume(hFileStream);
//    { set global flag }
//    bPaused := FALSE;
//    result := TRUE;
//  end;
end;

function STRPause: Boolean;
begin
  if not BASS_ChannelPause(hFileStream) then
  begin
    BASS_Error(BASS_ERRORGetCode, '');
    result := FALSE;
    exit;
  end;
  { set global flag }
  bPaused := TRUE;
  result := TRUE;
end;


function STROpen: Cardinal;
begin
  result := 0;
  BASS_STOP();
  BASS_START();
  hFileStream := 0;
  hFileStream := BASS_StreamCreateFile(FALSE, @Filename[1], 0, 0, BASS_MP3_SETPOS
    or BASS_STREAM_AUTOFREE);
  if hFileStream = 0 then
  begin
    BASS_Error(BASS_ErrorGetCode(), 'Fehler beim Laden der Datei.');
    exit;
  end;
  result := BASS_StreamGetLength(hFileStream);
end;

function STRStop: Boolean;
begin
  if not BASS_ChannelStop(hFileStream) then
  begin
    BASS_Error(BASS_ErrorGetCode(),
      'Wiedergabe konnte nicht angehalten werden.');
    result := FALSE;
    exit;
  end;
  { stop the timer }
  KillTimer(hApp, IDC_STRTIMER);
  result := TRUE;
end;

procedure STREndSession;
begin
  KillTimer(hApp, IDC_STRTIMER);
  BASS_Stop();
end;

function STRGetFileFromLB(idx: DWORD): string;
var
  buffer: array[0..MAX_PATH - 1] of Char;
begin
  SendDlgItemMessage(hApp, IDC_LSTPLAYLIST, LB_GETTEXT, idx, Integer(@buffer));
  result := string(buffer);
end;

