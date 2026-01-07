const
  IDC_CDTIMER = 201;

var
  hCDTimer: Cardinal = 0;
  CDLoop: Boolean = FALSE;

{ forward declaration of CDPlayTrack }
function CdPlayTrack(Track: DWORD): Cardinal; forward;
function CDStopTrack: Boolean; forward;

procedure CDTimerProc;
var
  TrackPos: Int64;
  s: string;
begin
  { adjust trackbar }
  TrackPos := BASS_ChannelGetPosition(CDChannel);
  SendDlgItemMessage(hApp, IDC_TRACKER, TBM_SETPOS, Integer(TRUE), TrackPos);
  s := FormatTime(BASS_CDGetTrackLength(CDTrack));
  SendDlgItemMessage(hApp, IDC_STATUSBAR, SB_SETTEXT, 0, Integer(@(s)[1]));
  if CDTrack = CDNumTracks then
  begin
    EnableWindow(GetDlgItem(hApp, IDC_BTNPRIOR), TRUE);
    EnableWindow(GetDlgItem(hApp, IDC_BTNNEXT), FALSE);
  end;
  if CDTrack = 1 then
  begin
    EnableWindow(GetDlgItem(hApp, IDC_BTNPRIOR), FALSE);
    EnableWindow(GetDlgItem(hApp, IDC_BTNNEXT), TRUE);
  end;
  { loop stuff }
  CDLoop := (IsDlgButtonChecked(hApp, IDC_CHKLOOP) = BST_CHECKED);
  if (BASS_ChannelIsActive(CDChannel) = BASS_ACTIVE_STOPPED) and CDLoop then
  begin
    BASS_ChannelSetPosition(CDChannel, 0);
    exit;
  end;
  { play next track }
  if (BASS_ChannelIsActive(CDChannel) = BASS_ACTIVE_STOPPED) and (CDTrack <
    BASS_CDGetTracks()) then
  begin
    Inc(CDTrack);
    CDPlayTrack(CDTrack);
    s := '[ '+IntToStr(CDTrack)+' / '+IntToStr(BASS_CDGetTracks())+' ]';
    SetDlgItemText(hApp, IDC_STCTRACKTITLE, @s[1]);
  end;
end;

function CDStartSession(var TrackLength, numTracks: DWORD): Boolean;
begin
  if not BASS_CDInit(nil, BASS_DEVICE_LEAVEVOL) then
  begin
    BASS_Error(BASS_ERRORGetCode, 'BASS_CDInit failed.');
    CheckDlgButton(hApp, IDC_RDBCD, BST_UNCHECKED);
    CheckDlgButton(hApp, IDC_RDBMP3, BST_CHECKED);
    BASS_CDFree();
    result := FALSE;
    exit;
  end;
  if not BASS_CDInDrive then
  begin
    BASS_Error(BASS_ERRORGetCode, 'No audio CD is available..');
    CheckDlgButton(hApp, IDC_RDBCD, BST_UNCHECKED);
    CheckDlgButton(hApp, IDC_RDBMP3, BST_CHECKED);
    BASS_CDFree();
    result := FALSE;
    exit;
  end;
  { set global flags }
  bCD := TRUE;
  TrackLength := BASS_CDGetTrackLength(1);
  numTracks := BASS_CDGetTracks();
  result := TRUE;
end;

function CDPlayTrack(Track: DWORD): Cardinal;
begin
  result := 0;
  if not bPaused then { track is beeing played at the moment (not paused) }
  begin
    { is requested track valid? }
    if (Track < 1) or (Track > BASS_CDGetTracks()) then
      exit;
    { play it }
    if not BASS_CDPlay(Track, FALSE, TRUE) then
    begin
      BASS_Error(BASS_ERRORGetCode, 'CD track cannot be played..');
      result := 0;
      exit;
    end;
    hCDTimer := SetTimer(hApp, IDC_CDTIMER, 10, @CDTimerProc);
    result := BASS_CDGetTrackLength(Track);
  end
  else { current track is paused }
  begin
    { resume }
    BASS_ChannelResume(CDChannel);
    { set global flag }
    bPaused := FALSE;
  end;
end;

function CDStopTrack: Boolean;
begin
  if not BASS_ChannelStop(CDCHANNEL) then
  begin
    BASS_Error(BASS_ERRORGetCode, 'Output could not be stopped..');
    result := FALSE;
    exit;
  end;
  { set global flags }
  bPaused := FALSE;
  //bPlaying := FALSE;
  KillTimer(hApp, IDC_CDTimer);
  result := TRUE;
end;

function CDPause: Boolean;
begin
  if not BASS_ChannelPause(CDCHANNEL) then
  begin
    BASS_Error(BASS_ERRORGetCode, '');
    result := FALSE;
    exit;
  end;
  { set global flag }
  bPaused := TRUE;
  result := TRUE;
end;

procedure CDEndSession;
begin
  { set global flags and variables }
  CDTrack := 0;
  bPaused := FALSE;
//  bPlaying := FALSE;
  bCD := FALSE;
  { stop timer }
  KillTimer(hApp, IDC_CDTIMER);
  { free BASS CD stuff }
  BASS_CDFree();
end;
