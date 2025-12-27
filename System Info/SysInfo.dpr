program SysInfo;

uses
  windows, messages, CommCtrl, tlhelp32, WinInfo, RamInfo, CPUInfo, HDDInfo,
  ProcessInfo;

{$R resource.res}
{$INCLUDE GUITools.inc}
{$INCLUDE AppTools.inc}
{$INCLUDE SysUtils.inc}
{$INCLUDE ntdll.pas}
{$INCLUDE FileTools.inc}

const

  IDC_BTNABOUT = 101;
  IDC_LV       = 102;
  IDC_MEMO     = 103;
  IDC_BTNKILLIT = 105;
  IDC_LB       = 106;
  IDC_LV2      = 107;
  IDC_LV3      = 108;
  IDC_BTNDETAILS = 109;
  IDC_STATUSBAR = 110;

  FontName     = 'Tahoma';
  FontSize     = -18;
  MemoFontName = 'Lucida Console';
  MemoFontSize = -13;

  CRLF         = #13#10;

const

  APPNAME      = 'SysInfo';
  VER          = '1.0';

  INFO_TEXT    = APPNAME + ' ' + VER + #13 + #10 +
    'Copyright © Your Name' + #13 + #10 + #13 + #10 +
    'https://github.com/';

var
  hApp, hImgList: Cardinal;
  fQuiet       : boolean = false;
  hModuleSnap  : Cardinal;
  bPrevState   : Boolean;

  Sender       : DWORD = 0; // Sender = 0 -> Prozesse, Sender = 1 -> Module

  ItemArray      : array[0..5] of string = ('Operating system', 'HDD/SSD',
    'Module',
    'Processes', 'Processor', 'Memory');

  whitebrush   : HBRUSH = 0;

  WhiteLB      : TLogBrush =
    (
    lbStyle: BS_SOLID;
    lbColor: $00FFFFFF;
    lbHatch: 0
    );

procedure MakeColsLV2;
var
  lvc          : TLVColumn;
begin
  lvc.mask := LVCF_TEXT or LVCF_WIDTH;
  lvc.pszText := 'Parameter';
  lvc.cx := 150;
  SendDlgItemMessage(hApp, IDC_LV2, LVM_INSERTCOLUMN, 0, Integer(@lvc));
  lvc.mask := lvc.mask;
  lvc.pszText := 'Value';
  lvc.cx := 200;
  SendDlgItemMessage(hApp, IDC_LV2, LVM_INSERTCOLUMN, 1, Integer(@lvc));
end;

procedure MakeColsLV3;
var
  lvc          : TLVColumn;
begin
  lvc.mask := LVCF_TEXT or LVCF_WIDTH;
  lvc.pszText := 'Process / Modul';
  lvc.cx := 200;
  SendDlgItemMessage(hApp, IDC_LV3, LVM_INSERTCOLUMN, 0, Integer(@lvc));
  lvc.mask := lvc.mask or LVCF_FMT;
  lvc.fmt := LVCFMT_RIGHT;
  lvc.pszText := 'PID';
  lvc.cx := 75;
  SendDlgItemMessage(hApp, IDC_LV3, LVM_INSERTCOLUMN, 1, Integer(@lvc));
end;

procedure GetWinInfo;
var
  lvi          : TLVItem;
  WinInfo      : TWinInfo;
begin
  ShowWindow(GetDlgItem(hApp, IDC_LV2), SW_SHOW);
  ShowWindow(GetDlgItem(hApp, IDC_MEMO), SW_HIDE);
  ShowWindow(GetDlgItem(hApp, IDC_BTNKILLIT), SW_HIDE);
  ShowWindow(GetDlgItem(hApp, IDC_BTNDETAILS), SW_HIDE);
  { Listview Create }
  SendDlgItemMessage(hApp, IDC_LV2, LVM_DELETEALLITEMS, 0, 0);
  ZeroMemory(@lvi, sizeof(lvi));
  lvi.mask := LVIF_TEXT;
  WinInfo := TWinInfo.Create;
  with WinInfo do
  begin
    try
      lvi.iSubItem := 0;
      lvi.iItem := 0;
      lvi.pszText := 'Administrator rights';
      lvi.iItem := SendDlgItemMessage(hApp, IDC_LV2, LVM_INSERTITEM, 0,
        Integer(@lvi));
      lvi.iSubItem := 1;
      if IsAdmin then
        lvi.pszText := 'yes'
      else
        lvi.pszText := 'no';
      SendDlgItemMessage(hApp, IDC_LV2, LVM_SETITEM, 0, Integer(@lvi));

      lvi.iSubItem := 0;
      lvi.pszText := 'User';
      lvi.iItem := SendDlgItemMessage(hApp, IDC_LV2, LVM_INSERTITEM, 0,
        Integer(@lvi));
      lvi.iSubItem := 1;
      lvi.pszText := pointer(UserName);
      SendDlgItemMessage(hApp, IDC_LV2, LVM_SETITEM, 0, Integer(@lvi));

      lvi.iSubItem := 0;
      lvi.iItem := 0;
      lvi.pszText := 'Computername';
      lvi.iItem := SendDlgItemMessage(hApp, IDC_LV2, LVM_INSERTITEM, 0,
        Integer(@lvi));
      lvi.iSubItem := 1;
      lvi.pszText := pointer(ComputerName);
      SendDlgItemMessage(hApp, IDC_LV2, LVM_SETITEM, 0, Integer(@lvi));

      lvi.iSubItem := 0;
      lvi.iItem := 0;
      lvi.pszText := 'Systempath';
      lvi.iItem := SendDlgItemMessage(hApp, IDC_LV2, LVM_INSERTITEM, 0,
        Integer(@lvi));
      lvi.iSubItem := 1;
      lvi.pszText := pointer(SysDir);
      SendDlgItemMessage(hApp, IDC_LV2, LVM_SETITEM, 0, Integer(@lvi));

      lvi.iSubItem := 0;
      lvi.pszText := 'Windowspath';
      lvi.iItem := SendDlgItemMessage(hApp, IDC_LV2, LVM_INSERTITEM, 0,
        Integer(@lvi));
      lvi.iSubItem := 1;
      lvi.pszText := pointer(WinDir);
      SendDlgItemMessage(hApp, IDC_LV2, LVM_SETITEM, 0, Integer(@lvi));

      lvi.iSubItem := 0;
      lvi.pszText := 'Version';
      lvi.iItem := SendDlgItemMessage(hApp, IDC_LV2, LVM_INSERTITEM, 0,
        Integer(@lvi));
      lvi.iSubItem := 1;
      lvi.pszText := pointer(Version);
      SendDlgItemMessage(hApp, IDC_LV2, LVM_SETITEM, 0, Integer(@lvi));

      lvi.iSubItem := 0;
      lvi.pszText := 'Operating system';
      lvi.iItem := SendDlgItemMessage(hApp, IDC_LV2, LVM_INSERTITEM, 0,
        Integer(@lvi));
      lvi.iSubItem := 1;
      lvi.pszText := pointer(OS);
      SendDlgItemMessage(hApp, IDC_LV2, LVM_SETITEM, 0, Integer(@lvi));
    finally
      WinInfo.Free;
    end;
  end;
end;

procedure GetHDDInfo;
var
  s            : string;
  HDDInfo      : THDDInfo;
  i            : Integer;
begin
  ShowWindow(GetDlgItem(hApp, IDC_LV2), SW_HIDE);
  ShowWindow(GetDlgItem(hApp, IDC_LV3), SW_HIDE);
  ShowWindow(GetDlgItem(hApp, IDC_BTNKILLIT), SW_HIDE);
  ShowWindow(GetDlgItem(hApp, IDC_BTNDETAILS), SW_HIDE);
  ShowWindow(GetDlgItem(hApp, IDC_MEMO), SW_SHOW);
  SetDlgItemText(hApp, IDC_MEMO, '');
  s := 'Information about hard drives and partitions' + CRLF + CRLF;
  HDDInfo := THDDInfo.create;
  try
    with HDDInfo do
    begin
      for i := 0 to HDDsCount - 1 do
      begin
        s := s + 'HDD/SSD: ' + IntToStr(i) + CRLF;
        s := s + '   Cylinder            : ' + IntToStr(Cylinders[i]) + CRLF;
        s := s + '   Tracks per Cylinder : ' + IntToStr(TracksPerCylinder[i]) +
          CRLF;
        s := s + '   Sectors per track   : ' + IntToStr(SectorsPerTrack[i]) +
          CRLF;
        s := s + '   Bytes pro Sektor    : ' + IntToStr(BytesPerSector[i]) +
          CRLF;
        s := s + '   Capacity            : ' + IntToStr(DiskSize[i]) + ' Bytes' +
          ' (' + IntToStr(DiskSize[i] div 1024 div 1024) + ' MB)' + CRLF;
        s := s + CRLF;
      end;
      for i := 0 to length(Partitions) - 1 do
      begin
        s := s + 'Partition: ' + Partitions[i] + CRLF;
        s := s + '   Offset          : ' + IntToStr(PartOffset[i]) + CRLF;
        s := s + '   Length          : ' + IntToStr(PartLength[i]) + ' Bytes' +
          CRLF;
        s := s + '   HDD/SSD         : ' + IntToStr(DiskNumber[i]) + CRLF;
        s := s + '   Label           : ' + PartLabel[i] + CRLF;
        s := s + '   File system     : ' + PartFileSystem[i] + CRLF;
        s := s + '   Capacity        : ' + FloatToStr(PartTotalSpace[i] / 1024 /
          1024, 2, 2) + ' MB' + CRLF;
        s := s + '   free Ram        : ' + FloatToStr(PartFreeSpace[i] / 1024 /
          1024, 2, 2) + ' MB' +
          ' (' + IntToStr(PartFreeSpace[i] * 100 div PartTotalSpace[i]) + '%)' +
            CRLF;
        s := s + CRLF;
      end;
    end;
  finally
    HDDInfo.Free;
  end;
  SetDlgItemText(hApp, IDC_MEMO, pointer(s));
end;

procedure GetProcs;
var
  lvi          : TLVItem;
  ProcInfo     : TProcessInfo;
  i            : Integer;
  s            : string;
begin
  ShowWindow(GetDlgItem(hApp, IDC_LV2), SW_HIDE);
  ShowWindow(GetDlgItem(hApp, IDC_LV3), SW_SHOW);
  ShowWindow(GetDlgItem(hApp, IDC_MEMO), SW_HIDE);
  ShowWindow(GetDlgItem(hApp, IDC_BTNKILLIT), SW_SHOW);
  ShowWindow(GetDlgItem(hApp, IDC_BTNDETAILS), SW_SHOW);
  { Listview Create }
  SendDlgItemMessage(hApp, IDC_LV3, LVM_DELETEALLITEMS, 0, 0);
  ZeroMemory(@lvi, sizeof(lvi));
  lvi.mask := LVIF_TEXT;
  ProcInfo := TProcessInfo.create;
  try
    for i := 0 to ProcInfo.cntProcesses - 1 do
    begin
      lvi.iItem := i;
      lvi.iSubItem := 0;
      lvi.pszText := pointer(ProcInfo.ProcessDetails[i].Filename);
      lvi.iItem := SendDlgItemMessage(hApp, IDC_LV3, LVM_INSERTITEM, 0,
        Integer(@lvi));
      lvi.iSubItem := 1;
      lvi.pszText := pointer(Format('0x%08X',
        [ProcInfo.ProcessDetails[i].ProcID]));
      SendDlgItemMessage(hApp, IDC_LV3, LVM_SETITEM, 0, Integer(@lvi));
    end;
  finally
    ProcInfo.Free;
  end;
  s := Format('Number of processes: %d', [SendDlgItemMessage(hApp, IDC_LV3,
    LVM_GETITEMCOUNT, 0, 0)]);
  SendDlgItemMessage(hApp, IDC_STATUSBAR, SB_SETTEXT, 2, Integer(@s[1]));
end;

procedure ShowProcInfo(dwProcID: DWORD);
const
  lf           = #13#10; { new line }
var
  ProcInfo     : TProcessInfo;
  s            : string;
  i            : Integer;
begin
  ProcInfo := TProcessInfo.Create;
  try
    s := 'Filename: ' + ProcInfo.ProcInfoByID(dwprocID).Filename + lf;
    s := s + Format('PID=0x%08X, ParentID=0x%08X, priority=%d, Threads=%d',
      [ProcInfo.ProcInfoByID(dwProcID).ProcID,
      ProcInfo.ProcInfoByID(dwProcID).ParentProcID,
        ProcInfo.ProcInfoByID(dwProcID).PriClassBase,
        ProcInfo.ProcInfoByID(dwProcID).cntThreads]) + lf;
    s := s + 'started: ' + ProcInfo.ProcInfoByID(dwProcID).StartTime + lf + lf;
    s := s + 'Module:' + lf;
    s := s + ProcInfo.ProcInfoByID(dwprocID).Path + lf;
    for i := 0 to ProcInfo.ProcInfoByID(dwProcID).cntModules - 1 do
    begin
      s := s + ProcInfo.ProcInfoByID(dwProcID).Modules[i] + ' ';
    end;
//    s := s + lf+lf;
//    s := s + 'Threads:'+lf;
//    s := s + '    ThreadID       Priorität'+lf;
//    for i := 0 to ProcInfo.ProcInfoByID(dwProcID).cntThreads-1 do
//    begin
//      s := s + Format(' 0x%08X          %02d',[ProcInfo.ProcInfoByID(dwProcID).ThreadInfo[i].ThreadID,
//        ProcInfo.ProcInfoByID(dwProcID).ThreadInfo[i].Priority])+lf;
//    end;
  finally
    ProcInfo.Free;
  end;
  Messagebox(hApp, pointer(s), 'Process-Details', MB_ICONINFORMATION);
end;

procedure KillIt(dwProcID: DWORD);
var
  hProcess     : Cardinal;
  dw           : DWORD;
begin
  { open the process and store the process-handle }
  hProcess := OpenProcess(SYNCHRONIZE or PROCESS_TERMINATE, False, dwProcID);
  { kill it }
  TerminateProcess(hProcess, 0);
  { TerminateProcess returns immediately, so wie have to verify the result via
    WaitfForSingleObject }
  dw := WaitForSingleObject(hProcess, 5000);
  case dw of
    { everythings's all right, we killed the process }
    WAIT_OBJECT_0: Messagebox(hApp, 'Prozess wurde beendet.', 'Prozess beenden',
        MB_ICONINFORMATION);
    { process could not be terminated after 5 seconds }
    WAIT_TIMEOUT:
      begin
        Messagebox(hApp,
          'The process could not be completed within 5 seconds..',
          'End process', MB_ICONSTOP);
        exit;
      end;
    { error in calling WaitForSingleObject }
    WAIT_FAILED:
      begin
        RaiseLastError(hApp);
        exit;
      end;
  end;
  { and refresh LV contend }
  GetProcs();
end;

procedure GetModules;
var
  lvi          : TLVItem;
  pe32         : TProcessEntry32;
  me32         : TModuleEntry32;
  n, i         : Integer;
  s            : string;
  hSnapShot    : THandle;
  buffer       : array[0..MAX_PATH] of Char;
begin
  ShowWindow(GetDlgItem(hApp, IDC_LV2), SW_HIDE);
  ShowWindow(GetDlgItem(hApp, IDC_MEMO), SW_HIDE);
  ShowWindow(GetDlgItem(hApp, IDC_BTNDETAILS), SW_HIDE);
  ShowWindow(GetDlgItem(hApp, IDC_BTNKILLIT), SW_HIDE);
  ShowWindow(GetDlgItem(hApp, IDC_LV3), SW_SHOW);
  ShowWindow(GetDlgItem(hApp, IDC_BTNDETAILS), SW_SHOW);
  SendDlgItemMessage(hApp, IDC_LB, LB_RESETCONTENT, 0, 0);
  SetDlgItemText(hApp, IDC_MEMO, '');
  { make the snapshot }
  hModuleSnap := CreateToolHelp32SnapShot(TH32CS_SNAPPROCESS, 0);
  { test }
  if hModuleSnap = INVALID_HANDLE_VALUE then
  begin
    RaiseLastError(hApp);
    exit;
  end;
  { prepare pe32 and me32 }
  ZeroMemory(@pe32, sizeof(pe32));
  pe32.dwSize := sizeof(TProcessEntry32);
  ZeroMemory(@me32, sizeof(me32));
  me32.dwSize := sizeof(TModuleEntry32);
  { walk the processes }
  if Process32First(hModuleSnap, pe32) then
    while Process32Next(hModuleSnap, pe32) do
    begin
      { snap the modules }
      hSnapShot := CreateToolHelp32SnapShot(TH32CS_SNAPMODULE,
        pe32.th32ProcessID);
      { walk the modules for the specific process }
      while Module32Next(hSnapShot, me32) do
      begin
        s := me32.szExePath;
        { only add module to invisible listbox if not yet added }
        n := SendDlgItemMessage(hApp, IDC_LB, LB_FINDSTRINGEXACT, -1,
          Integer(@s[1]));
        Processmessages(hApp);
        if n = LB_ERR then
        begin
          s := me32.szExePath;
          SendDlgItemMessage(hApp, IDC_LB, LB_ADDSTRING, 0, Integer(@s[1]));
        end;
      end;
    end;
  { copy listbox entries to the listview }
  SendDlgItemMessage(hApp, IDC_LV3, LVM_DELETEALLITEMS, 0, 0);
  ZeroMemory(@lvi, sizeof(lvi));
  lvi.mask := LVIF_TEXT;
  for i := 0 to SendDlgItemMessage(hApp, IDC_LB, LB_GETCOUNT, 0, 0) - 1 do
  begin
    SendDlgItemMessage(hApp, IDC_LB, LB_GETTEXT, i, Integer(@buffer));
    s := string(buffer);
    s := Cutpathname(s);
    lvi.iItem := i;
    lvi.iSubItem := 0;
    lvi.pszText := pointer(s);
    SendDlgItemMessage(hApp, IDC_LV3, LVM_INSERTITEM, 0, Integer(@lvi));
    lvi.iSubItem := 1;
    lvi.pszText := '';
    SendDlgItemMessage(hApp, IDC_LV3, LVM_SETITEM, 0, Integer(@lvi));
  end;
  { display numbers of loaded modules }
  s := Format('Number of modules: %d', [SendDlgItemMessage(hApp, IDC_LV3,
    LVM_GETITEMCOUNT, 0, 0)]);
  SendDlgItemMessage(hApp, IDC_STATUSBAR, SB_SETTEXT, 2, Integer(@s[1]));
end;

procedure ShowModuleInfo(Idx: Integer);
const
  lf           = #13#10; { new line }
var
  hSnap,
    hSnap2     : THandle;
  pe32         : TProcessEntry32;
  me32         : TModuleEntry32;
  s            : string;
  buffer       : array[0..MAX_PATH] of Char;
begin
  { get the modulename }
  SendDlgItemMessage(hApp, IDC_LB, LB_GETTEXT, Idx, Integer(@buffer));
  s := Format('Path: %s', [buffer]);
  { make a snapshot }
  hSnap := CreateToolHelp32SnapShot(TH32CS_SNAPPROCESS, 0);
  { test }
  if hSnap = INVALID_HANDLE_VALUE then
  begin
    RaiseLastError(hApp);
    exit;
  end;
  { prepare pe32 and me32 }
  ZeroMemory(@pe32, sizeof(pe32));
  pe32.dwSize := sizeof(TProcessEntry32);
  ZeroMemory(@me32, sizeof(me32));
  me32.dwSize := sizeof(TModuleEntry32);
  { walk the processes }
  if Process32First(hSnap, pe32) then
  begin
    s := s + lf + lf;
    { headline }
    s := s + 'Process-Information' + lf;
    s := s + 'PID                    Prozess' + lf;
    while Process32Next(hSnap, pe32) do
    begin
      hSnap2 := CreateToolHelp32SnapShot(TH32CS_SNAPMODULE, pe32.th32ProcessID);
      while Module32Next(hSnap2, me32) do
      begin
        if lstrcmpi(me32.szExePath, buffer) = 0 then
          s := s + Format('0x%08X     %s', [pe32.th32ProcessID, pe32.szExeFile])
            + lf;
      end;
    end;
  end;
  Messagebox(hApp, pointer(s), 'Modul-Details', MB_ICONINFORMATION);
end;

procedure GetCPUInfo;
var
  lvi          : TLVItem;
  CPUInfo      : TCPUInfo;
begin
  ShowWindow(GetDlgItem(hApp, IDC_LV2), SW_SHOW);
  ShowWindow(GetDlgItem(hApp, IDC_MEMO), SW_HIDE);
  ShowWindow(GetDlgItem(hApp, IDC_LV3), SW_HIDE);
  ShowWindow(GetDlgItem(hApp, IDC_BTNKILLIT), SW_HIDE);
  ShowWindow(GetDlgItem(hApp, IDC_BTNDETAILS), SW_HIDE);
  { Listview vorbereiten }
  SendDlgItemMessage(hApp, IDC_LV2, LVM_DELETEALLITEMS, 0, 0);
  ZeroMemory(@lvi, sizeof(lvi));
  lvi.mask := LVIF_TEXT;
  CPUInfo := TCPUInfo.create;
  try
    with CPUInfo do
    begin
      lvi.iSubItem := 0;
      lvi.pszText := 'Stepping';
      lvi.iItem := SendDlgItemMessage(hApp, IDC_LV2, LVM_INSERTITEM, 0,
        Integer(@lvi));
      lvi.iSubItem := 1;
      lvi.pszText := pointer(IntToStr(Stepping));
      SendDlgItemMessage(hApp, IDC_LV2, LVM_SETITEM, 0, Integer(@lvi));
      lvi.iSubItem := 0;
      lvi.pszText := 'Model';
      lvi.iItem := SendDlgItemMessage(hApp, IDC_LV2, LVM_INSERTITEM, 0,
        Integer(@lvi));
      lvi.iSubItem := 1;
      lvi.pszText := pointer(IntToStr(Model));
      SendDlgItemMessage(hApp, IDC_LV2, LVM_SETITEM, 0, Integer(@lvi));
      lvi.iSubItem := 0;
      lvi.pszText := 'Family';
      lvi.iItem := SendDlgItemMessage(hApp, IDC_LV2, LVM_INSERTITEM, 0,
        Integer(@lvi));
      lvi.iSubItem := 1;
      lvi.pszText := pointer(IntToStr(Family));
      SendDlgItemMessage(hApp, IDC_LV2, LVM_SETITEM, 0, Integer(@lvi));
      lvi.iSubItem := 0;
      lvi.pszText := 'Frequency';
      lvi.iItem := SendDlgItemMessage(hApp, IDC_LV2, LVM_INSERTITEM, 0,
        Integer(@lvi));
      lvi.iSubItem := 1;
      lvi.pszText := pointer(FloatToStr(CPUSpeed, 0, 0) + ' MHz');
      SendDlgItemMessage(hApp, IDC_LV2, LVM_SETITEM, 0, Integer(@lvi));
      lvi.iSubItem := 0;
      lvi.pszText := 'Manufacturer';
      lvi.iItem := SendDlgItemMessage(hApp, IDC_LV2, LVM_INSERTITEM, 0,
        Integer(@lvi));
      lvi.iSubItem := 1;
      lvi.pszText := pointer(Manufacturer);
      SendDlgItemMessage(hApp, IDC_LV2, LVM_SETITEM, 0, Integer(@lvi));
      lvi.iSubItem := 0;
      lvi.pszText := 'Typ';
      lvi.iItem := SendDlgItemMessage(hApp, IDC_LV2, LVM_INSERTITEM, 0,
        Integer(@lvi));
      lvi.iSubItem := 1;
      lvi.pszText := pointer(CPUType);
      SendDlgItemMessage(hApp, IDC_LV2, LVM_SETITEM, 0, Integer(@lvi));
      lvi.iSubItem := 0;
      lvi.pszText := 'Processorname';
      lvi.iItem := SendDlgItemMessage(hApp, IDC_LV2, LVM_INSERTITEM, 0,
        Integer(@lvi));
      lvi.iSubItem := 1;
      lvi.pszText := pointer(CPUName);
      SendDlgItemMessage(hApp, IDC_LV2, LVM_SETITEM, 0, Integer(@lvi));
    end;
  finally
    CPUInfo.Free;
  end;
end;

procedure GetRAMInfo;
var
  lvi          : TLVItem;
  RAMInfo      : TRAMInfo;
begin
  ShowWindow(GetDlgItem(hApp, IDC_LV2), SW_SHOW);
  ShowWindow(GetDlgItem(hApp, IDC_MEMO), SW_HIDE);
  ShowWindow(GetDlgItem(hApp, IDC_BTNKILLIT), SW_HIDE);
  ShowWindow(GetDlgItem(hApp, IDC_BTNDETAILS), SW_HIDE);
  { Listview vorbereiten }
  SendDlgItemMessage(hApp, IDC_LV2, LVM_DELETEALLITEMS, 0, 0);
  ZeroMemory(@lvi, sizeof(lvi));
  lvi.mask := LVIF_TEXT;
  RAMInfo := TRAMInfo.create;
  try
    with RAMInfo do
    begin
      lvi.iSubItem := 0;
      lvi.pszText := 'used memory';
      lvi.iItem := SendDlgItemMessage(hApp, IDC_LV2, LVM_INSERTITEM, 0,
        Integer(@lvi));
      lvi.iSubItem := 1;
      lvi.pszText := pointer(IntToStr(UsedMemory) + ' %');
      SendDlgItemMessage(hApp, IDC_LV2, LVM_SETITEM, 0, Integer(@lvi));
      lvi.iSubItem := 0;
      lvi.pszText := 'available swap file';
      lvi.iItem := SendDlgItemMessage(hApp, IDC_LV2, LVM_INSERTITEM, 0,
        Integer(@lvi));
      lvi.iSubItem := 1;
      lvi.pszText := pointer(IntToStr(AvailpageFile div 1024) + ' KB');
      SendDlgItemMessage(hApp, IDC_LV2, LVM_SETITEM, 0, Integer(@lvi));
      lvi.iSubItem := 0;
      lvi.pszText := 'Pagefile';
      lvi.iItem := SendDlgItemMessage(hApp, IDC_LV2, LVM_INSERTITEM, 0,
        Integer(@lvi));
      lvi.iSubItem := 1;
      lvi.pszText := pointer(IntToStr(TotalPageFile div 1024) + ' KB');
      SendDlgItemMessage(hApp, IDC_LV2, LVM_SETITEM, 0, Integer(@lvi));
      lvi.iSubItem := 0;
      lvi.pszText := 'Available memory';
      lvi.iItem := SendDlgItemMessage(hApp, IDC_LV2, LVM_INSERTITEM, 0,
        Integer(@lvi));
      lvi.iSubItem := 1;
      lvi.pszText := pointer(IntToStr(AvailMemory div 1024) + ' KB');
      SendDlgItemMessage(hApp, IDC_LV2, LVM_SETITEM, 0, Integer(@lvi));
      lvi.iSubItem := 0;
      lvi.pszText := 'memory';
      lvi.iItem := SendDlgItemMessage(hApp, IDC_LV2, LVM_INSERTITEM, 0,
        Integer(@lvi));
      lvi.iSubItem := 1;
      lvi.pszText := pointer(IntToStr(TotalMemory div 1024) + ' KB');
      SendDlgItemMessage(hApp, IDC_LV2, LVM_SETITEM, 0, Integer(@lvi));
    end;
  finally
    RAMInfo.Free;
  end;
end;

{-----------------------------------------------------------------------------
  Procedure : CpuThreadProc
  Author    : Eugen Honeker
  Arguments : lParam: Pointer
  Result    : DWORD
-----------------------------------------------------------------------------}
function CpuThread(lParam: Pointer): DWORD; stdcall;
var
  spi          : SYSTEM_PERFORMANCE_INFORMATION;
  sti          : SYSTEM_TIME_INFORMATION;
  sbi          : SYSTEM_BASIC_INFORMATION;
  nOldIdleTime,
    nOldSystemTime: INT64;
  nNewCPUTime  : ULONG;
  s            : string;
begin
  nOldIdleTime := 0;
  nOldSystemTime := 0;

  if (NTQuerySystemInformation(SYS_BASIC_INFO, @sbi,
    sizeof(SYSTEM_BASIC_INFORMATION), 0) = NO_ERROR) then
  begin
    while not fQuiet do
    begin
      if (NTQuerySystemInformation(SYS_TIME_INFO, @sti,
        sizeof(SYSTEM_TIME_INFORMATION), 0) = NO_ERROR) then
        if (NTQuerySystemInformation(SYS_PERFORMANCE_INFO, @spi,
          sizeof(SYSTEM_PERFORMANCE_INFORMATION), 0) = NO_ERROR) then
        begin
          if (nOldIdleTime <> 0) then
          begin
            nNewCPUTime := trunc(100 - ((spi.nIdleTime - nOldIdleTime) /
              (sti.nKeSystemTime - nOldSystemTime) * 100) / sbi.bKeNumberProcessors
              + 0.5);
            if (nNewCPUTime <> nOldIdleTime) then
            begin
              s := Format('CPU usage: %d%%', [nNewCPUTIME]);
              SendDlgItemMessage(hApp, IDC_STATUSBAR, SB_SETTEXT, 3,
                Integer(@s[1]));
            end;
          end;
          nOldIdleTime := spi.nIdleTime;
          nOldSystemTime := sti.nKeSystemTime;
          Sleep(500); //Update every 500ns
        end;
    end;
  end;
  Result := 0;
end;

function MemoryThread(p: Pointer): DWORD; stdcall;
var
  RAMInfo      : TRAMInfo;
  s            : string;
begin
  while not fQuiet do
  begin
    RAMInfo := TRAMInfo.create;
    try
      s := 'free memory: ' + IntToStr(100 - RAMInfo.UsedMemory) + '%';
      SendDlgItemMessage(hApp, IDC_STATUSBAR, SB_SETTEXT, 1, Integer(@s[1]));
      s := 'SysInfo RAM free: ' + IntToStr(100 - RAMInfo.UsedMemory) + '%';
      SetWindowText(hApp, pointer(s));
      sleep(500);
    finally
      RAMInfo.Free;
    end;
  end;
  result := 0;
end;

var
  SortOrder    : Integer = 0;
{-----------------------------------------------------------------------------
  Procedure : SortLV
  Purpose   : sorting the main listview
  Arguments : None
  Result    : None
-----------------------------------------------------------------------------}
procedure SortLV(hLV: HWND);
var
  lvi          : TLVItem;
  Loop         : Integer;
begin
  lvi.mask := LVIF_PARAM;
  lvi.iSubItem := 0;
  lvi.iItem := 0;

  for Loop := 0 to SendDlgItemMessage(hApp, IDC_LV3, LVM_GETITEMCOUNT, 0, 0) - 1
    do
  begin
    lvi.lParam := lvi.iItem;
    SendDlgItemMessage(hApp, IDC_LV3, LVM_SETITEM, 0, LPARAM(@lvi));
    Inc(lvi.iItem);
  end;
end;

{-----------------------------------------------------------------------------
  Procedure : CompareItems
  Purpose   : comparing the items of the main listview
  Arguments : lParam1, lParam2, SortType: lParam
  Result    : Integer
-----------------------------------------------------------------------------}
function CompareItems(lParam1, lParam2, SortType: LPARAM): integer; stdcall;
var
  buf1,
    buf2       : array[0..255] of char;
begin
  result := 0;
  ZeroMemory(@buf1, sizeof(buf1));
  ZeroMemory(@buf2, sizeof(buf2));

  ListView_GetItemText(GetDlgItem(hApp, IDC_LV3), lParam2, SortType, buf1,
    sizeof(buf1));
  ListView_GetItemText(GetDlgItem(hApp, IDC_LV3), lParam1, SortType, buf2,
    sizeof(buf2));
  case SortOrder of
    0: Result := lstrcmpi(buf2, buf1);
    1: Result := lstrcmpi(buf1, buf2);
  end;
end;

function GetItemPID: Integer;
var
  lvi          : TLVItem;
  Buffer       : array[0..255] of Char;
begin
  lvi.iItem := SendDlgItemMessage(hApp, IDC_LV3, LVM_GETNEXTITEM, -1,
    LVNI_FOCUSED);
  lvi.iSubItem := 1;
  lvi.mask := LVIF_TEXT;
  lvi.pszText := Buffer;
  lvi.cchTextMax := 256;
  SendDlgItemMessage(hApp, IDC_LV3, LVM_GETITEM, 0, Integer(@lvi));
  result := StrToInt(string(Buffer));
end;

{*******************************************************************************

  Best of my love - Eagles

  Every night I'm lyin' in bed
  holdin' you close in my dreams,
  thinkin' about all the things that we said
  and comin' apart at the seams.
  We try to talk it over but the words come out too rough.
  I know you were tryin' to give me the best of your love.

                               for my greates love - Heike

*******************************************************************************}

function dlgfunc(hDlg: hWnd; uMsg: dword; wParam: wParam; lParam: lParam): bool;
  stdcall;
var
  hStatusBar   : Cardinal;
  MyFont       : HFONT;
  s            : string;
  PanelWidth   : array[0..3] of Integer;
  i            : Integer;
  lvi          : TLVItem;
  lpnmia       : TNMITEMACTIVATE;
  WinInfo      : TWinInfo;
  mmi          : PMINMAXINFO;
  rc           : TRect;
  buffer       : array[0..MAX_PATH] of Char;
  IdxLB        : Integer;
begin
  result := true;
  case uMsg of
    WM_INITDIALOG:
      begin
        hApp := hDlg;
        SendMessage(hDlg, WM_SETICON, ICON_BIG, Integer(LoadIcon(hInstance,
          MAKEINTRESOURCE(1))));

        hImgList := ImageList_Create(32, 32, ILC_COLOR32, 6, 1);
        ImageList_AddIcon(hImgList, LoadImage(hInstance, MAKEINTRESOURCE(3),
          IMAGE_ICON, 32, 32, LR_LOADTRANSPARENT));
        ImageList_AddIcon(hImgList, LoadImage(hInstance, MAKEINTRESOURCE(4),
          IMAGE_ICON, 32, 32, LR_LOADTRANSPARENT));
        ImageList_AddIcon(hImgList, LoadImage(hInstance, MAKEINTRESOURCE(5),
          IMAGE_ICON, 32, 32, LR_LOADTRANSPARENT));
        ImageList_AddIcon(hImgList, LoadImage(hInstance, MAKEINTRESOURCE(6),
          IMAGE_ICON, 32, 32, LR_LOADTRANSPARENT));
        ImageList_AddIcon(hImgList, LoadImage(hInstance, MAKEINTRESOURCE(7),
          IMAGE_ICON, 32, 32, LR_LOADTRANSPARENT));
        ImageList_AddIcon(hImgList, LoadImage(hInstance, MAKEINTRESOURCE(8),
          IMAGE_ICON, 32, 32, LR_LOADTRANSPARENT));
        SendDlgItemMessage(hDlg, IDC_LV, LVM_SETIMAGELIST, LVSIL_NORMAL,
          hImgList);
        ZeroMemory(@lvi, sizeof(TLVItem));
        lvi.mask := LVIF_TEXT or LVIF_IMAGE;
        lvi.iItem := 0;
        for i := 0 to 5 do
        begin
          lvi.pszText := pointer(ItemArray[i]);
          lvi.iImage := i;
          SendDlgItemMessage(hApp, IDC_LV, LVM_INSERTITEM, 0, Integer(@lvi));
        end;

        PanelWidth[0] := 175;
        PanelWidth[1] := 300;
        PanelWidth[2] := 450;
        PanelWidth[3] := 550;
        hStatusBar := CreateStatusWindow(WS_CHILD or WS_VISIBLE, '', hDlg,
          IDC_STATUSBAR);
        SendMessage(hStatusbar, SB_SETPARTS, 4, Integer(@PanelWidth));
        WinInfo := TWinInfo.Create;
        try
          s := 'Computername: ' + WinInfo.ComputerName;
          SendDlgItemMessage(hDlg, IDC_STATUSBAR, SB_SETTEXT, 0, Integer(@s[1]));
        finally
          WinInfo.Free;
        end;

        MyFont := CreateFont(FontSize, 0, 0, 0, 900, 0, 0, 0, ANSI_CHARSET,
          OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
          DEFAULT_PITCH, FontName);
        if MyFont <> 0 then
          SendDlgItemMessage(hDlg, 999, WM_SETFONT, Integer(MyFont),
            Integer(true));
        s := APPNAME;
        SetWindowText(hDlg, pointer(s));
        SetDlgItemText(hDlg, 999, pointer(s));

        MyFont := CreateFont(MemoFontSize, 0, 0, 0, 500, 0, 0, 0, ANSI_CHARSET,
          OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
          DEFAULT_PITCH, memoFontName);
        if MyFont <> 0 then
          SendDlgItemMessage(hDlg, IDC_MEMO, WM_SETFONT, Integer(MyFont),
            Integer(true));

        CreateToolTips(hDlg);
        AddToolTip(hDlg, IDC_BTNABOUT, @ti, 'Information about the program');
        AddToolTip(hDlg, IDC_BTNKILLIT, @ti, 'Ends the selected process');

        CloseHandle(CreateThread(nil, 0, @MemoryThread, nil, 0, DWORD(nil^)));
        CloseHandle(CreateThread(nil, 0, @CpuThread, nil, 0, DWORD(nil^)));
        GetProcs();
        ShowWindow(GetDlgItem(hApp, IDC_LV3), SW_HIDE);
        MakeColsLV2;
        MakeColsLV3;
        SendDlgItemMessage(hDlg, IDC_LV2, LVM_SETEXTENDEDLISTVIEWSTYLE, 0,
          LVS_EX_FULLROWSELECT);
        SendDlgItemMessage(hDlg, IDC_LV3, LVM_SETEXTENDEDLISTVIEWSTYLE, 0,
          LVS_EX_FULLROWSELECT);
        GetWinInfo();
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
          103:
            begin
              whitebrush := CreateBrushIndirect(WhiteLB);
              SetBkColor(wParam, WhiteLB.lbColor);
              result := BOOL(whitebrush);
            end;
        end;
      end;
    WM_LBUTTONDOWN: SendMessage(hDlg, WM_NCLBUTTONDOWN, HTCAPTION, lParam);
    WM_SIZE:
      begin
        MoveWindow(GetDlgItem(hDlg, 999), 0, 0, loword(lParam), 75, TRUE);
        s := APPNAME + ' ' + VER;
        SetDlgItemText(hDlg, 999, pointer(s));
        SetWindowPos(GetDlgItem(hDlg, 101), GetDlgItem(hDlg, 999), loword(lParam)
          - 47, 7, 40, 22, 0);
        MoveWindow(GetDlgItem(hDlg, 102), 0, 80, 117, hiword(lParam) - 100,
          TRUE);
        MoveWindow(GetDlgItem(hDlg, IDC_MEMO), 120, 80, loword(lParam) - 118,
          hiword(lParam) - 132, TRUE);
        MoveWindow(GetDlgItem(hDlg, IDC_LV2), 120, 80, loword(lParam) - 118,
          hiword(lParam) - 132, TRUE);
        MoveWindow(GetDlgItem(hDlg, IDC_LV3), 120, 80, loword(lParam) - 118,
          hiword(lParam) - 132, TRUE);
        MoveWindow(GetDlgItem(hDlg, IDC_BTNKILLIT), 415, hiword(lParam) - 48,
          100, 24, TRUE);
        MoveWindow(GetDlgItem(hDlg, IDC_BTNDETAILS), 520, hiword(lParam) - 48,
          100, 24, TRUE);
        MoveWindow(GetDlgItem(hDlg, IDC_STATUSBAR), 0, 0, loword(lParam),
          hiword(lParam) - 135, TRUE);
      end;
    WM_GETMINMAXINFO:
      begin
        mmi := PMINMAXINFO(lParam);
        mmi.ptMinTrackSize.X := 575;
        mmi.ptMinTrackSize.Y := 430;
      end;
    WM_CLOSE:
      begin
        DestroyWindow(hDlg);
        PostQuitMessage(0);
      end;
    WM_COMMAND:
      begin
        if wParam = ID_CANCEL then
          SendMessage(hDlg, WM_CLOSE, 0, 0);
        if hiword(wParam) = BN_CLICKED then
        begin
          case LoWord(wParam) of
            IDC_BTNABOUT: MyMessagebox(hDlg, 'Information', INFO_TEXT, 2);
            IDC_BTNKILLIT:
              begin
                KillIt(GetItemPID);
              end;
            IDC_BTNDETAILS:
              begin
                if Sender = 0 then
                  ShowProcInfo(GetItemPID())
                else
                begin
                  ZeroMemory(@lvi, sizeof(lvi));
              { which entry is marked? }
                  lvi.iItem := SendDlgItemMessage(hApp, IDC_LV3, LVM_GETNEXTITEM,
                    -1, LVNI_FOCUSED);
                  lvi.iSubItem := 0;
                  lvi.mask := LVIF_TEXT;
                  lvi.pszText := Buffer;
                  lvi.cchTextMax := 256;
              { Get Caption }
                  SendDlgItemMessage(hApp, IDC_LV3, LVM_GETITEM, 0,
                    Integer(@lvi));
                  s := string(buffer);
                  IdxLB := 0;
                  for i := 0 to SendDlgItemMessage(hDlg, IDC_LB, LB_GETCOUNT, 0,
                    0) - 1 do
                  begin
                    SendDlgItemMessage(hDlg, IDC_LB, LB_GETTEXT, i,
                      Integer(@buffer));
                    if s = CutPathname(string(buffer)) then
                    begin
                      IdxLB := i;
                      break;
                    end;
                  end;
                  ShowModuleInfo(IdxLB);
                end;
              end;
          end;
        end;
      end;
    WM_NOTIFY:
      begin
        ZeroMemory(@lpnmia, sizeof(TNMITEMACTIVATE));
        if PNMHdr(lParam).idFrom = IDC_LV then
        begin
          case PNMHdr(lParam)^.code of
            NM_CLICK:
              begin
                case PNMITEMACTIVATE(lParam)^.iItem of
                  5: GetWinInfo();
                  4: GetHDDInfo();
                  3:
                    begin
                      Sender := 1;
                      GetModules();
                      SortOrder := 0;
                      SendDlgItemMessage(hApp, IDC_LV3, LVM_SORTITEMS, 0,
                        Integer(@CompareItems));
                      SortLV(GetDlgItem(hApp, IDC_LV3));
                      SendDlgItemMessage(hApp, IDC_LV3, LVM_SORTITEMS, 0,
                        Integer(@CompareItems));
                      SortLV(GetDlgItem(hApp, IDC_LV3));
                      SortOrder := 1;
                    end;
                  2:
                    begin
                      Sender := 0;
                      GetProcs();
                      SortOrder := 0;
                      SendDlgItemMessage(hApp, IDC_LV3, LVM_SORTITEMS, 0,
                        Integer(@CompareItems));
                      SortLV(GetDlgItem(hApp, IDC_LV3));
                      SendDlgItemMessage(hApp, IDC_LV3, LVM_SORTITEMS, 0,
                        Integer(@CompareItems));
                      SortLV(GetDlgItem(hApp, IDC_LV3));
                      SortOrder := 1;
                    end;
                  1: GetCPUInfo();
                  0: GetRAMInfo();
                end;
              end;
            LVN_ITEMCHANGED:
              begin
                case PNMLISTVIEW(lParam).iItem of
                  5: GetWinInfo();
                  4: GetHDDInfo();
                  3:
                    begin
                      Sender := 1;
                      GetModules();
                      SortOrder := 0;
                      SendDlgItemMessage(hApp, IDC_LV3, LVM_SORTITEMS, 0,
                        Integer(@CompareItems));
                      SortLV(GetDlgItem(hApp, IDC_LV3));
                      SendDlgItemMessage(hApp, IDC_LV3, LVM_SORTITEMS, 0,
                        Integer(@CompareItems));
                      SortLV(GetDlgItem(hApp, IDC_LV3));
                      SortOrder := 1;
                    end;
                  2:
                    begin
                      Sender := 0;
                      GetProcs();
                      SortOrder := 0;
                      SendDlgItemMessage(hApp, IDC_LV3, LVM_SORTITEMS, 0,
                        Integer(@CompareItems));
                      SortLV(GetDlgItem(hApp, IDC_LV3));
                      SendDlgItemMessage(hApp, IDC_LV3, LVM_SORTITEMS, 0,
                        Integer(@CompareItems));
                      SortLV(GetDlgItem(hApp, IDC_LV3));
                      SortOrder := 1;
                    end;
                  1: GetCPUInfo();
                  0: GetRAMInfo();
                end;
              end;
          end;
        end;
        if (PNMHdr(lParam).idFrom = IDC_LV2) or (PNMHdr(lParam).idFrom = IDC_LV3)
          then
        begin
          case PNMHdr(lParam)^.code of
            NM_CUSTOMDRAW:
              begin
                with PNMLVCUSTOMDRAW(lParam)^ do
                begin
                  case nmcd.dwDrawStage of
                    CDDS_PREPAINT:
                      begin
                  //result:= BOOL(CDRF_NOTIFYITEMDRAW);
                        SetWindowLong(hDlg, DWL_MSGRESULT, CDRF_NOTIFYITEMDRAW);
                      end;
                    CDDS_ITEMPREPAINT:
                      begin
                        if (nmcd.uItemState and CDIS_FOCUS <> 0) then
                        begin
                          clrText := $00FF0000;
                          clrTextBk := $00E8E8E8;
                          lvi.stateMask := LVIS_SELECTED;
                          lvi.state := 0;
                          SendMessageW(PNMHdr(lParam).hwndFrom, LVM_SETITEMSTATE,
                            nmcd.dwItemSpec, longint(@lvi));
                    //result:= BOOL({CDRF_DODEFAULT or} CDRF_NOTIFYPOSTPAINT);
                          SetWindowLong(hDlg, DWL_MSGRESULT,
                            CDRF_NOTIFYPOSTPAINT);
                        end
                        else
                    //result:= BOOL(CDRF_DODEFAULT);
                          SetWindowLong(hDlg, DWL_MSGRESULT, CDRF_DODEFAULT);
                      end;
                    CDDS_ITEMPOSTPAINT:
                      begin
                        if (nmcd.uItemState and CDIS_FOCUS <> 0) then
                        begin
                          lvi.stateMask := LVIS_SELECTED;
                          lvi.state := $FF;
                          SendMessageW(PNMHdr(lParam).hwndFrom, LVM_SETITEMSTATE,
                            nmcd.dwItemSpec, longint(@lvi));
                          rc.Left := LVIR_SELECTBOUNDS;
                          if (SendMessageW(PNMHdr(lParam).hwndFrom,
                            LVM_GETITEMRECT, nmcd.dwItemSpec, longint(@rc)) <> 0)
                            then
                            with rc do
                            begin
                              inc(left, 2);
                              PatBlt(nmcd.hdc, left, top, 1, bottom - top,
                                BLACKNESS);
                              PatBlt(nmcd.hdc, right - 1, top, 1, bottom - top,
                                BLACKNESS);
                              PatBlt(nmcd.hdc, left, top, right - left, 1,
                                BLACKNESS);
                              PatBlt(nmcd.hdc, left, bottom - 1, right - left, 1,
                                BLACKNESS);
                            end;
                        end;
                      end; //  CDDS_ITEMPOSTPAINT:
                  else
                //result:= BOOL(CDRF_DODEFAULT);
                    SetWindowLong(hDlg, DWL_MSGRESULT, CDRF_DODEFAULT);
                  end; //  case nmcd.dwDrawStage of
                end; //  with PNMLVCUSTOMDRAW(pnmh)^ do
              end; //  NM_CUSTOMDRAW:
          end;
        end;
        if PNMHdr(lParam).idFrom = IDC_LV3 then
        begin
          case PNMHdr(lParam)^.code of
            LVN_COLUMNCLICK:
              begin
                if (PNMHdr(lParam)^.idFrom = IDC_LV3) then
                begin
                  ListView_SortItems(GetDlgItem(hApp, IDC_LV3), @CompareItems,
                    PNMListView(lParam)^.iSubItem);
                  SortLV(PNMHdr(lParam)^.idFrom);
                  if SortOrder = 0 then
                    SortOrder := 1
                  else
                    Sortorder := 0;
                end;
              end;
          end;
        end;
      end
  else
    result := false;
  end;
end;

{ Get Privileges }
function EnablePrivilege(const Privilege: string; fEnable: Boolean; out
  PreviousState: Boolean): DWORD;
var
  Token        : THandle;
  NewState     : TTokenPrivileges;
  Luid         : TLargeInteger;
  PrevState    : TTokenPrivileges;
  Return       : DWORD;
begin
  PreviousState := True;
  if (GetVersion() > $80000000) then
    // Win9x
    Result := ERROR_SUCCESS
  else
  begin
    // WinNT
    if not OpenProcessToken(GetCurrentProcess(), MAXIMUM_ALLOWED, Token) then
      Result := GetLastError()
    else
    try
      if not LookupPrivilegeValue(nil, PChar(Privilege), Luid) then
        Result := GetLastError()
      else
      begin
        NewState.PrivilegeCount := 1;
        NewState.Privileges[0].Luid := Luid;
        if fEnable then
          NewState.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED
        else
          NewState.Privileges[0].Attributes := 0;
        if not AdjustTokenPrivileges(Token, False, NewState,
          SizeOf(TTokenPrivileges), PrevState, Return) then
          Result := GetLastError()
        else
        begin
          Result := ERROR_SUCCESS;
          PreviousState :=
            (PrevState.Privileges[0].Attributes and SE_PRIVILEGE_ENABLED <> 0);
        end;
      end;
    finally
      CloseHandle(Token);
    end;
  end;
end;

const
  SE_DEBUG_NAME = 'SeDebugPrivilege';

begin
  InitCommonControls;
  EnablePrivilege(SE_DEBUG_NAME, TRUE, bPrevState);
  DialogBox(hInstance, MAKEINTRESOURCE(100), 0, @dlgfunc);
  EnablePrivilege(SE_DEBUG_NAME, FALSE, bPrevState);
end.

