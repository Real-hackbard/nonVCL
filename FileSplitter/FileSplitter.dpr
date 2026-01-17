{$A+,B-,C+,D+,E-,F-,G+,H+,I+,J-,K-,L+,M-,N+,O+,P+,Q-,R-,S-,T-,U-,V+,W-,X+,Y+,Z1}
{$MINSTACKSIZE $00004000}
{$MAXSTACKSIZE $00100000}
{$IMAGEBASE $00400000}
{$APPTYPE GUI}

program FileSplitter;

uses
  windows,
  messages,
  CommDlg,
  ShlObj,
  CommCtrl,
  ShellAPI,
  MpuTools in 'units\MpuTools.pas',
  globals in 'units\globals.pas';

{$R 'res\Resource.res'}

type
  TSplitThreadParams = record
    FileToSplit: array[0..MAX_PATH] of Char;
    DestFolder: array[0..MAX_PATH] of Char;
    SizeOfParts: Int64;
  end;
  PSplitThreadParams = ^TSplitThreadParams;

var
  TickStart         : DWORD;

function GetVersionInfo(var VersionString, Description: string): DWORD;
type
  PDWORDArr = ^DWORDArr;
  DWORDArr = array[0..0] of DWORD;
var
  VerInfoSize       : DWORD;
  VerInfo           : Pointer;
  VerValueSize      : DWORD;
  VerValue          : PVSFixedFileInfo;
  LangInfo          : PDWORDArr;
  LangID            : DWORD;
  Desc              : PChar;
  i                 : Integer;
begin
  result := 0;
  VerInfoSize := GetFileVersionInfoSize(PChar(ParamStr(0)), LangID);
  if VerInfoSize <> 0 then
  begin
    VerInfo := Pointer(GlobalAlloc(GPTR, VerInfoSize));
    if Assigned(VerInfo) then
    try
      if GetFileVersionInfo(PChar(ParamStr(0)), 0, VerInfoSize, VerInfo) then
      begin
        if VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize) then
        begin
          with VerValue^ do
          begin
            VersionString := Format('%d.%d.%d.%d', [dwFileVersionMS shr 16, dwFileVersionMS and $FFFF,
              dwFileVersionLS shr 16, dwFileVersionLS and $FFFF]);
          end;
        end
        else
          VersionString := '';
        // Description
        if VerQueryValue(VerInfo, '\VarFileInfo\Translation', Pointer(LangInfo), VerValueSize) then
        begin
          if (VerValueSize > 0) then
          begin
            // Divide by element size since this is an array
            VerValueSize := VerValueSize div sizeof(DWORD);
            // Number of language identifiers in the table
           (********************************************************************)
            for i := 0 to VerValueSize - 1 do
            begin
              // Swap words of this DWORD
              LangID := (LoWord(LangInfo[i]) shl 16) or HiWord(LangInfo[i]);
              // Query value ...
              if VerQueryValue(VerInfo, @Format('\StringFileInfo\%8.8x\FileDescription', [LangID])[1], Pointer(Desc),
                VerValueSize) then
                Description := Desc;
            end;
            (********************************************************************)
          end;
        end
        else
          Description := '';
      end;
    finally
      GlobalFree(THandle(VerInfo));
    end
    else // GlobalAlloc
      result := GetLastError;
  end
  else // GetFileVersionInfoSize
    result := GetLastError;
end;

function GetCheck(hDlg: THandle; ID: DWORD): Boolean;
begin
  Result := IsDlgButtonChecked(hDlg, ID) = BST_CHECKED;
end;

function SetCheck(bCheck: Boolean): DWORD;
begin
  if bCheck then
    Result := BST_CHECKED
  else
    Result := BST_UNCHECKED;
end;

function BuildBatchFile(BatchFilename: string): Integer;
var
  s                 : string;
  Loop              : Integer;
  F                 : TextFile;
  len               : Integer;
begin
  s := 'copy /b ';
  len := length(Files);
  for Loop := 0 to len - 1 do
  begin
    s := s + '"' + Files[Loop] + '"' + ' + ';
  end;
  s := copy(s, 0, length(s) - 2);
  s := s + ' ' + '"' + ChangeFileExt(Files[0], '') + '"';

  AssignFile(F, BatchFilename);
{$I-}
  Rewrite(F);
{$I+}
  if IOResult = 0 then
  begin
    Writeln(F, s);
    CloseFile(F);
  end;
  result := GetLastError();
end;

function SplitFile(Filename, DestFolder: string; SplitSize: Int64): Integer;

  function GetClusterSize(Drive: Char): Cardinal;
  var
    SectorPerCluster: Cardinal;
    BytesPerSector  : Cardinal;
    NumberOfFreeClusters: Cardinal;
    TotalNumberOfClusters: Cardinal;
  begin
    GetDiskFreeSpace(PChar(Drive + ':\'), SectorPerCluster, BytesPerSector, NumberOfFreeClusters,
      TotalNumberOfClusters);
    Result := SectorPerCluster * BytesPerSector;
  end;

var
  hFile             : THandle;
  SizeOfFile        : Int64;
  hPart             : THandle;
  i                 : Cardinal;
  Partname          : string;
  BlockSize         : Cardinal;
  MemBuffer         : array of Byte;
  minlen            : Int64;
  BytesToRead, BytesRead, BytesWritten: Int64;
  OverallBytesRead  : Int64;
  ProgressCurrent, ProgressOld: Int64;
begin
  TickStart := GetTickCount;

  BlockSize := -(-GetClusterSize(FileName[1]) and -GetClusterSize(DestFolder[1]) and -1048576);
  SetLength(MemBuffer, BlockSize - 1);
  bRunning := 1;
  OverallBytesRead := 0;
  SizeOfFile := GetFileSize(PChar(Filename));
  hFile := CreateFile(PChar(Filename), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL
    or FILE_FLAG_SEQUENTIAL_SCAN or FILE_FLAG_WRITE_THROUGH, 0);
  if hFile <> INVALID_HANDLE_VALUE then
  begin
    i := 0;
    while OverallBytesRead < SizeOfFile do
    begin
      Inc(i);
      // Reset variables
      ProgressOld := 0;
      BytesToRead := SplitSize;
      // build filename of the parts
      Partname := DestFolder + '\' + ExtractFilename(Filename) + Format('.%3.3d', [i]);
      if FileExists(Partname) then
        DeleteFile(PChar(Partname));
      hPart := CreateFile(PChar(Partname), GENERIC_WRITE, FILE_SHARE_WRITE, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL
        or FILE_FLAG_SEQUENTIAL_SCAN or FILE_FLAG_WRITE_THROUGH, 0);
      if hPart <> INVALID_HANDLE_VALUE then
      begin
        repeat
          minlen := Min(length(MemBuffer), BytesToRead);
          BytesRead := FileRead(hFile, MemBuffer[0], minLen);
          if BytesRead > -1 then
          begin
            BytesWritten := FileWrite(hPart, MemBuffer[0], BytesRead);
            Dec(BytesToRead, length(MemBuffer));
            // progress stuff ////////////////////////////////////////////////////
            OverallBytesRead := OverallBytesRead + BytesWritten;
            ProgressCurrent := (OverallBytesRead * 100) div SizeOfFile;
            if ProgressCurrent <> ProgressOld then
            begin
              ProgressOld := ProgressCurrent;
            end;
            SendMessage(hApp, FSM_PROGRESS, ProgressCurrent, Integer(PChar(Partname)));
          end
          else
          begin
            MessageBoxW(hApp, PWideChar(SysErrorMessage(GetLastError)), PWideChar(WideString(APPNAME)), 0);
            Break;
          end;
          //////////////////////////////////////////////////////////////////////
        until (BytesToRead <= 0) or (bRunning = 0);
      end;
      FileClose(hPart);
      if bRunning = 0 then
        Break;
    end;
    FileClose(hFile);
  end;
  SendMessage(hApp, FSM_FINISH, GetTickCount - TickStart, GetLastError());
  result := GetLastError();
end;

function SplitThread(Param: Pointer): Integer;
var
  Filename          : string;
  DestFolder        : string;
  SplitSize         : Int64;
  ECode             : Integer;
begin
  result := 0;
  Filename := PSplitThreadParams(Param)^.FileToSplit;
  DestFolder := PSplitThreadParams(Param)^.DestFolder;
  SplitSize := PSplitThreadParams(Param)^.SizeOfParts;
  ECode := SplitFile(Filename, DestFolder, SplitSize);
  if bRunning = 1 then
  begin
    if (ECode = 0) or (ECode = 183) then
    begin
      BuildBatchFile(DestFolder + '\' + ChangeFileExt(ExtractFilename(Filename), '.bat'));
    end
    else
      Messagebox(0, @SysErrorMessage(ECode)[1], APPNAME, MB_ICONSTOP);
  end;
  Dispose(Param);
end;

function CalcCntParts(const Filename: string; Size: Int64): Cardinal;
var
  FileSize          : Int64; // >4GB
begin
  result := 0;
  if Size > 0 then
  begin
    FileSize := GetFileSize(PChar(Filename));
    if (FileSize > 0) and (FileSize div Size < High(Int64)) then
      result := (FileSize - 1) div Int64(Size) + 1;
  end;
end;

function CalcFileSize(const Filename: string; CntParts: Cardinal): Int64;
var
  FileSize          : Int64;
begin
  Result := 0;
  FileSize := GetFileSize(PChar(Filename));
  if (FileSize > 0) and (CntParts <> 0) then
  begin
    Result := (FileSize div CntParts) + 1;
  end;
end;

procedure EnableControls(hDlg: HWND; Enabled: Boolean);
begin
  EnableWindow(GetDlgItem(hDlg, IDC_BTNSPLIT), Enabled);
  EnableWindow(GetDlgItem(hDlg, IDC_BTNCANCEL), Enabled);
  EnableWindow(GetDlgItem(hDlg, IDC_EDTFILETOSPLIT), Enabled);
  EnableWindow(GetDlgItem(hDlg, IDC_BTNOPENSPLITFILE), Enabled);
  EnableWindow(GetDlgItem(hDlg, IDC_EDTTARGETFOLDER), Enabled);
  EnableWindow(GetDlgItem(hDlg, IDC_BTNSELFOLDER), Enabled);
  EnableWindow(GetDlgItem(hDlg, IDC_CHKCOPYTODISK), Enabled);
  EnableWindow(GetDlgItem(hDlg, IDC_EDTFILESIZE), Enabled);
end;

function dlgfunc(hDlg: hWnd; uMsg: dword; wParam: wParam; lParam: lParam):
  bool; stdcall;
var
  MyFont            : HFONT;
  rect              : TRect;
  pt                : TPoint;
  dwReturn          : DWORD;
  Version           : string;
  Description       : string;
  SplitThreadParams : PSplitThreadParams;
  buffer            : array[0..MAX_PATH] of Char;
  s                 : string;
  Translated        : LongBool;

  hThread           : THandle;
  ThreadID          : Cardinal;
  Speed             : string;
begin
  result := true;
  case uMsg of
    WM_INITDIALOG:
      begin
        Files := nil;
        hApp := hDlg;
        if SendMessage(hDlg, WM_SETICON, ICON_BIG, Integer(LoadIcon(hInstance, MAKEINTRESOURCE(1)))) = 0 then
          SendMessage(hDlg, WM_SETICON, ICON_SMALL, Integer(LoadIcon(hInstance, MAKEINTRESOURCE(1))));
        MyFont := CreateFont(FontSize, 0, 0, 0, 900, 0, 0, 0, ANSI_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
          DEFAULT_QUALITY, DEFAULT_PITCH, FontName);
        if MyFont <> 0 then
          SendDlgItemMessage(hDlg, 999, WM_SETFONT, Integer(MyFont), Integer(true));
        s := APPNAME;
        SetWindowText(hDlg, pointer(s));

        SendDlgItemMessage(hDlg, IDC_UDPARTS, UDM_SETRANGE32, 1, 999);
        EnableControl(hDlg, IDC_OPT_SIZE, FALSE);
        EnableControl(hDlg, IDC_OPT_PARTS, FALSE);
        EnableControl(hDlg, IDC_UDPARTS, FALSE);
        SendDlgItemMessage(hDlg, IDC_EDT_SIZE, EM_SETREADONLY, -1, 0);
        SendDlgItemMessage(hDlg, IDC_EDT_PARTS, EM_SETREADONLY, -1, 0);
        SendDlgItemMessage(hDlg, IDC_EDT_PARTS, EM_SETLIMITTEXT, 3, 0);
        CheckDlgButton(hDlg, IDC_OPT_SIZE, BST_CHECKED);
      end;
    WM_CTLCOLORSTATIC:
      begin
        case GetDlgCtrlId(lParam) of
          999:
            begin
              whitebrush := CreateBrushIndirect(WhiteLB);
              SetBkColor(wParam, WhiteLB.lbColor);
              result := BOOL(whitebrush);
            end;
        else
          SetBkColor(wParam, GetSysColor(COLOR_BTNFACE));
          SetBkMode(wParam, TRANSPARENT);
          result := BOOL(GetSysColorBrush(COLOR_BTNFACE));
        end;
      end;
    { let's move it, move it }
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
        SetWindowPos(GetDlgItem(hDlg, 124), GetDlgItem(hDlg, 999), loword(lParam) - 47, 7, 40, 22, 0);
        SetWindowPos(GetDlgItem(hDlg, 129), GetDlgItem(hDlg, 999), loword(lParam) - 47, 35, 40, 22, 0);
        GetWindowRect(GetDlgItem(hDlg, 999), rect);
        pt.X := rect.Left;
        pt.Y := rect.Bottom;
        ScreenToClient(hDlg, pt);
        MoveWindow(GetDlgItem(hDlg, 998), 0, pt.Y, rect.Right - rect.Left, 2, True);
        MoveWindow(GetDlgItem(hDlg, 997), 0, 250, rect.Right - rect.Left, 2, True);
      end;
    WM_COMMAND:
      begin
        if wParam = ID_CANCEL then
          SendMessage(hDlg, WM_CLOSE, 0, 0);
        if hiword(wParam) = BN_CLICKED then
        begin
          case loword(wParam) of
            IDC_BTNABOUT:
              begin
                dwReturn := GetVersionInfo(Version, Description);
                if dwReturn = 0 then
                begin
                  s := Format(INFO_TEXT, [Version, Description]);
                  MyMessageBox(hDlg, APPNAME, s, 1);
                end
                else
                  MessageboxW(hDlg, PWChar(SysErrorMessage(dwReturn)), PWideChar(WideString(APPNAME)), MB_ICONSTOP);
              end;
            IDC_BTNOPENSPLITFILE:
              begin
                SetDlgItemText(hDlg, IDC_EDT_SIZE, nil);
                SetDlgItemText(hDlg, IDC_EDT_PARTS, nil);
                FileToSplit := OpenFile(hDlg, '');
                if FileToSplit <> '' then
                begin
                  SetDlgItemText(hDlg, IDC_EDTFILETOSPLIT, PChar(FileToSplit));
                  FileSize := GetFilesize(FileToSplit);
                  Str(FileSize / 1024 / 1024: 0: 2, s);
                  SetWindowText(GetDlgItem(hDlg, IDC_STCSTATUSWND), PChar(s + ' MB'));
                end;
              end;
            IDC_BTNSELFOLDER:
              begin
                dwReturn := GetFolder(hDlg, 0, rsChooseFolder, TargetDir);
                if dwReturn = 0 then
                  SetDlgItemText(hDlg, IDC_EDTTARGETFOLDER, PChar(TargetDir))
                else
                  MessageboxW(hDlg, PWideChar(SysErrorMessage(dwReturn)), PWideChar(WideString(APPNAME)), MB_ICONSTOP);
              end;
            IDC_OPT_SIZE, IDC_OPT_PARTS:
              begin
                SendDlgItemMessage(hDlg, IDC_EDT_SIZE, EM_SETREADONLY, Integer(not GetCheck(hDlg, IDC_OPT_SIZE)), 0);
                SendDlgItemMessage(hDlg, IDC_EDT_PARTS, EM_SETREADONLY, Integer(GetCheck(hDlg, IDC_OPT_SIZE)), 0);
                EnableControl(hDlg, IDC_UDPARTS, not GetCheck(hDlg, IDC_OPT_SIZE));
                if loword(wParam) = IDC_OPT_SIZE then
                  SetFocus(GetDlgItem(hDlg, IDC_EDT_SIZE));
                if loword(wParam) = IDC_OPT_PARTS then
                  SetFocus(GetDlgItem(hDlg, IDC_EDT_PARTS));
              end;
            IDC_BTNSPLIT:
              begin
                Idx := 0;
                setlength(Files, 0);
                New(SplitThreadParams);
                GetDlgItemText(hDlg, IDC_EDTFILETOSPLIT, buffer, sizeof(buffer));
                lstrcpy(SplitThreadParams.FileToSplit, buffer);
                GetDlgItemText(hDlg, IDC_EDTTARGETFOLDER, buffer, sizeof(buffer));
                lstrcpy(SplitThreadParams.DestFolder, Buffer);
                SplitThreadParams.SizeOfParts := SizeOfParts;
                SetLength(Files, CountParts);
                hThread := BeginThread(nil, 0, SplitThread, SplitThreadParams, 0, ThreadID);
                if hThread <> 0 then
                begin
                  CloseHandle(hThread);
                  EnableControls(hDlg, False);
                  EnableWindow(GetDlgItem(hDlg, IDC_BTNCANCEL), True);
                end;
              end;
            IDC_BTNCANCEL:
              begin
                InterlockedExchange(bRunning, 0);
              end;
          end;
        end;
        if hiword(wParam) = EN_CHANGE then { edit changed }
        begin
          case loword(wParam) of
            IDC_EDTFILETOSPLIT, IDC_EDTTARGETFOLDER:
              begin
                GetDlgItemText(hDlg, IDC_EDTFILETOSPLIT, buffer, MAX_PATH);
                FileToSplit := string(buffer);
                GetDlgItemText(hDlg, IDC_EDTTARGETFOLDER, buffer, MAX_PATH);
                TargetDir := string(buffer);

                EnableControl(hDlg, IDC_OPT_SIZE, (FileExists(FileToSplit)) and (DirectoryExists(TargetDir)));
                SendDlgItemMessage(hDlg, IDC_EDT_SIZE, EM_SETREADONLY, Integer(not (FileExists(FileToSplit) and
                  (DirectoryExists(TargetDir)))), 0);
                EnableControl(hDlg, IDC_OPT_PARTS, (FileExists(FileToSplit)) and (DirectoryExists(TargetDir)));

                //if not FileExists(FileToSplit) then
//                  SetDlgItemText(hDlg, IDC_STCSTATUSWND, PChar(rsFileNotExists))
//                else
//                  SetDlgItemText(hDlg, IDC_STCSTATUSWND, '');
//                if not DirectoryExists(TargetDir) then
//                  SetDlgItemText(hDlg, IDC_STCSTATUSWND, PChar(rsFolderNotExists))
//                else
//                  SetDlgItemText(hDlg, IDC_STCSTATUSWND, '');

                if ((FileExists(FileToSplit)) and (DirectoryExists(TargetDir)) and (SizeOfParts > 0))
                  or ((FileExists(FileToSplit)) and (DirectoryExists(TargetDir)) and (CountParts > 1)) then
                  EnableControl(hDlg, IDC_BTNSPLIT, True)
                else
                  EnableControl(hDlg, IDC_BTNSPLIT, False);
              end;
            IDC_EDT_SIZE:
              begin
                if GetCheck(hDlg, IDC_OPT_SIZE) then
                begin
                  SizeOfParts := GetDlgItemInt(hDlg, IDC_EDT_SIZE, Translated, False);
                  SizeOfParts := SizeOfParts  * 1024 * 1024;
                  CountParts := CalcCntParts(FileToSplit, SizeOfParts);
                  SetDlgItemInt(hDlg, IDC_EDT_PARTS, CountParts, False);
                end;
                if ((FileExists(FileToSplit)) and (DirectoryExists(TargetDir)) and (SizeOfParts > 1))
                  or ((FileExists(FileToSplit)) and (DirectoryExists(TargetDir)) and (CountParts > 1)) then
                  EnableControl(hDlg, IDC_BTNSPLIT, True)
                else
                  EnableControl(hDlg, IDC_BTNSPLIT, False);
              end;
            IDC_EDT_PARTS:
              begin
                if not GetCheck(hDlg, IDC_OPT_SIZE) then
                begin
                  CountParts := GetDlgItemInt(hDlg, IDC_EDT_PARTS, Translated, False);
                  SizeOfParts := CalcFileSize(FileToSplit, CountParts);
                  Str((SizeOfParts / 1024 / 1024): 0: 3, s);
                  SetDlgItemText(hDlg, IDC_EDT_SIZE, PChar(s));
                end;
                if ((FileExists(FileToSplit)) and (DirectoryExists(TargetDir)) and (SizeOfParts > 1))
                  or ((FileExists(FileToSplit)) and (DirectoryExists(TargetDir)) and (CountParts > 1)) then
                  EnableControl(hDlg, IDC_BTNSPLIT, True)
                else
                  EnableControl(hDlg, IDC_BTNSPLIT, False);
              end;
          end;
        end;
      end;
    WM_CLOSE:
      begin
        EndDialog(hDlg, 0);
      end;
    FSM_PROGRESS:
      begin
        s := ExtractFilename(string(PChar(Pointer(lParam))));
        if (s <> PrevFile) and (Idx <= High(Files)) then
        begin
          Files[Idx] := s;
          PrevFile := s;
          Inc(Idx);
        end;
        SetDlgItemText(hDlg, IDC_STCSTATUSWND, PChar(s));
        s := Format('%d%% - %s', [wParam, APPNAME]);
        SetWindowText(hDlg, PChar(s));
      end;
    FSM_FINISH:
      begin
        EnableControls(hDlg, True);
        EnableWindow(GetDlgItem(hDlg, IDC_BTNCANCEL), False);
        SetDlgItemText(hDlg, IDC_STCSTATUSWND, '');
        SetWindowText(hDlg, PChar(APPNAME));
        Str(wParam / 1000: 0: 2, s);
        //s := Format('Dauer: %d msec', [WParam]);
        Str((FileSize / (wParam / 1000) / 1024 / 1024): 0: 2, Speed);
        SetDlgItemText(hDlg, IDC_STCSTATUSWND, PChar(s + ' sec [' + Speed + ' MB/sec]'));
      end;
  else
    result := false;
  end;
end;

begin
  InitCommonControls;
  DialogBox(hInstance, MAKEINTRESOURCE(100), 0, @dlgfunc);
end.

