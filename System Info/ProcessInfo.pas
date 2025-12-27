unit ProcessInfo;

interface

uses windows, tlhelp32;

type
  TThreadRecord = record
    ThreadID    : Integer;
    Priority    : Integer;
  end;

  ThreadRecordArray = array of TThreadRecord;
  UsedModulesArray = array of String;

  TProcessRecord = record
    Filename     : String;
    Path         : String;
    ProcID       : Integer;
    ParentProcID : Integer;
    PriClassBase : Integer;
    cntThreads   : Integer;
    ThreadInfo   : ThreadRecordArray;
    StartTime    : String;
    cntModules   : Integer;
    Modules      : UsedModulesArray;
  end;

  ProcessRecordArray = array of TProcessRecord;

type TProcessInfo = class
  private
    FDetailsAllProcs     : ProcessRecordArray;
    FDetailsSingleProc   : TProcessRecord;
    FbPrevState          : Boolean;
    FcntProcesses        : Integer;
    function Snapshot    : Integer;
    function EnableDebugPrivileges(bEnable: Boolean; var PreviousState: Boolean): DWORD;
    function ft2st(ft: FILETIME): String;
    function GetAllProcs : ProcessRecordArray;
  public
    constructor create;
    destructor Free;
    property cntProcesses   : Integer read FcntProcesses;
    property ProcessDetails : ProcessRecordArray read GetAllProcs;
    function ProcInfoByID(ID: DWORD): TProcessRecord;
end;

implementation

constructor TProcessInfo.create;
begin
  EnableDebugPrivileges(TRUE, FbPrevState);
  FCntProcesses := SnapShot;
end;

destructor TProcessInfo.Free;
begin
  EnableDebugPrivileges(FALSE, FbPrevState);
end;

function TProcessInfo.EnableDebugPrivileges(bEnable: Boolean; var PreviousState: Boolean): DWORD;
const
  SE_DEBUG_NAME = 'SeDebugPrivilege';
var
  Token: THandle;
  NewState: TTokenPrivileges;
  Luid: TLargeInteger;
  PrevState: TTokenPrivileges;
  Return: DWORD;
begin
  PreviousState := TRUE;
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
      if not LookupPrivilegeValue(nil, SE_DEBUG_NAME, Luid) then
        Result := GetLastError()
      else
      begin
        NewState.PrivilegeCount := 1;
        NewState.Privileges[0].Luid := Luid;
        if bEnable then
          NewState.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED
        else
          NewState.Privileges[0].Attributes := 0;
        if not AdjustTokenPrivileges(Token, False, NewState,
          SizeOf(TTokenPrivileges), PrevState, Return) then
          Result := GetLastError()
        else
        begin
          Result := ERROR_SUCCESS;
          PreviousState := (PrevState.Privileges[0].Attributes and SE_PRIVILEGE_ENABLED <> 0);
        end;
      end;
    finally
      CloseHandle(Token);
    end;
  end;
end;

function TProcessInfo.ft2st(ft: FILETIME): String;
var
  st  : TSYSTEMTIME;
  lft : TFILETIME;
  buf : array[0..MAX_PATH]of char;
  s1, s2   : String;
begin
  st.wYear             := 1970;
  st.wMonth            := 1;
  st.wDayOfWeek        := 0;
  st.wDay              := 1;
  st.wHour             := 0;
  st.wMinute           := 0;
  st.wSecond           := 0;
  st.wMilliseconds     := 0;
  FileTimeToLocalFileTime(ft, lft);
  FileTimeToSystemTime(lft,st);
  if (GetTimeFormat(LOCALE_USER_DEFAULT, TIME_FORCE24HOURFORMAT, @st, nil, buf,
    sizeof(buf)) > 0) then
      s1 := String(buf);
  if (GetDateFormat(LOCALE_USER_DEFAULT, DATE_SHORTDATE, @st, nil, buf,
    sizeof(buf)) > 0) then
      s2 := String(buf);
  result := s2+' '+s1;
end;

function TProcessInfo.Snapshot: Integer;
var
  hSnapShot          : Cardinal;
  pe32               : TProcessEntry32;
  cntP               : Integer;
begin
  result := 0;
  hSnapShot := CreateToolHelp32SnapShot(TH32CS_SNAPPROCESS, 0);
  if hSnapShot <> 0 then
  begin
    ZeroMemory(@pe32, sizeof(pe32));
    pe32.dwSize := sizeof(ProcessEntry32);
    cntP := 0;
    if Process32First(hSnapShot, pe32) = true then
    begin
      while Process32Next(hSnapShot, pe32) = true do
      begin
        setlength(FDetailsAllprocs, cntP+1);
        FDetailsAllprocs[cntP].Filename := pe32.szExeFile;
        FDetailsAllprocs[cntP].ProcID := pe32.th32ProcessID;
        Inc(cntP);
      end;
      result := cntP;
    end;
  end;
end;

function TProcessInfo.GetAllProcs: ProcessRecordArray;
begin
  result := FDetailsAllprocs;
end;

function TProcessInfo.ProcInfoByID(ID: DWORD): TProcessRecord;
var
  hSnap, hSnapModule : THandle;
  pe32  : TProcessEntry32;
  me32  : TModuleEntry32;
  th32  : TThreadEntry32;
  hProc : Cardinal;
  cntT  : Integer;
  nPriority : Integer;
  ftct, ftet,
  ftkt, ftut    : TFILETIME;
  cntM  : Cardinal;
begin
  ZeroMemory(@pe32, sizeof(pe32));
  pe32.dwSize := sizeof(TProcessEntry32);
  hSnap := CreateToolHelp32SnapShot(TH32CS_SNAPPROCESS, 0);
  if Process32First(hSnap, pe32) = TRUE then
  begin
    while Process32Next(hSnap, pe32) = TRUE do
    begin
      if pe32.th32ProcessID = ID then
        break;
    end;
    FDetailsSingleProc.Filename := pe32.szExeFile;
    FDetailsSingleProc.ProcID := pe32.th32ProcessID;
    FDetailsSingleProc.ParentProcID := pe32.th32ParentProcessID;
    FDetailsSingleProc.PriClassBase := pe32.pcPriClassBase;
    FDetailsSingleProc.cntThreads := pe32.cntThreads;
    hProc := OpenProcess(PROCESS_QUERY_INFORMATION, FALSE, pe32.th32ProcessID);
    GetprocessTimes(hProc, ftct, ftet, ftkt, ftut);
    FDetailsSingleProc.StartTime := ft2st(ftct);
    hSnapModule := CreateToolHelp32SnapShot(TH32CS_SNAPMODULE, pe32.th32ProcessID);
    if hSnapModule <> 0 then
    begin
      cntM := 0;
      ZeroMemory(@me32, sizeof(me32));
      me32.dwSize := sizeof(TModuleEntry32);
      if Module32First(hSnapModule, me32) = TRUE then
      begin
        FDetailsSingleProc.Path := me32.szExePath;
        while Module32Next(hSnapModule, me32) = TRUE do
        begin
          setlength(FDetailsSingleProc.Modules, cntM+1);
          FDetailsSingleProc.Modules[cntM] := me32.szExePath;
          Inc(cntM);
        end;
        FDetailsSingleProc.cntModules := cntM;
      end;
    end;
    hSnap := CreateToolHelp32SnapShot(TH32CS_SNAPTHREAD, pe32.th32ProcessID);
    ZeroMemory(@th32, sizeof(TThreadEntry32));
    th32.dwSize := sizeof(TTHreadEntry32);
    cntT := 0;
    if Thread32First(hSnap, th32) = TRUE then
      while Thread32Next(hSnap, th32) = TRUE do
      begin
        if th32.th32OwnerProcessID = pe32.th32ProcessID then
        begin
          setlength(FDetailsSingleProc.ThreadInfo, cntT+1);
          nPriority := th32.tpBasePri+th32.tpDeltaPri;
          if (th32.tpBasePri < 16) and (th32.tpDeltaPri > 15) then nPriority := 15;
          if (th32.tpBasePri > 15) and (th32.tpDeltaPri > 31) then nPriority := 31;
          if (th32.tpBasePri < 16) and (th32.tpDeltaPri > 1) then nPriority  := 1;
          if (th32.tpBasePri > 15) and (th32.tpDeltaPri < 16) then nPriority := 16;
          FDetailsSingleProc.ThreadInfo[cntT].Priority := nPriority;
          FDetailsSingleProc.ThreadInfo[cntT].ThreadID := th32.th32ThreadID;
          Inc(cntT);
        end;
      end;
  end;
  result := FDetailsSingleProc;
end;

end.
