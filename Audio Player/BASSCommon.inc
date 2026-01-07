procedure BASS_Error(ECode: Integer; EMsg: string);
begin
  MessageBox(hApp, pointer('BASS Error-Code: ' + IntToStr(ECode) + #13#10 +
    EMsg), 'BASS Error', MB_ICONSTOP);
end;

procedure BASSInit;
begin
  if not BASS_Init(-1, 44100, BASS_DEVICE_LEAVEVOL, hApp) then
  begin
    BASS_Error(BASS_ERRORGetCode, 'Bass initialization failed.');
    exit;
  end;
end;

procedure BASSSetTrackPos(handle: Cardinal; idx: int64);
begin
  if BASS_ACTIVE_PLAYING = BASS_ChannelIsActive(handle) then
    BASS_ChannelPause(handle);
  if not BASS_ChannelSetPosition(handle, idx) then
  begin
    BASS_Error(BASS_ERRORGetCode,
      'The position in the title could not be changed..');
    exit;
  end;
  BASS_ChannelResume(handle);
end;

function BASSGetBitRate(handle: Cardinal): DWORD;
var
  len: Cardinal;
begin
  len := Round(BASS_ChannelBytes2Seconds(handle, BASS_StreamGetLength(handle)));
  result := Round(BASS_StreamGetFilePosition(handle, BASS_FILEPOS_END) * 8 / len
    / 1000)
end;

function BASSGetFreq(handle: Cardinal): DWORD;
var
  freq, volume: Cardinal;
  pan: Integer;
begin
  BASS_ChannelGetAttributes(handle, freq, volume, pan);
  result := freq;
end;

function BASSGetMode(handle: Cardinal): string;
var
  flags: DWORD;
begin
  flags := BASS_ChannelGetFlags(handle);
  if (flags and BASS_SAMPLE_MONO) > 0 then
    result := 'mono'
  else
    result := 'Stereo';
end;