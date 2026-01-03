unit MpuProcessTools;

interface

uses
  Windows,
  Psapi,
  Tlhelp32,
  MpuList;

{$I NativeWinAPI.inc}

type
  TMpuProcToolException = class
  protected
    FMsg: WideString;
    FCode: DWord;
  public
    constructor Create(const msg: WideString); overload;
    constructor Create(const msg: WideString; Errorcode: DWord); overload;
    constructor CreateFmt(Msg: WideString; const Args: array of TVarRec);
    property Message: WideString read FMsg;
    property Errorcode: DWord read FCode;
  end;

type
  TProcess = class(TObject)
  private
    FModuleFilename: WideString;
    FModulePath: WideString;
    FProcID: DWORD;
    FParentProcID: DWORD;
    FPOwnerSID: PSID;
    FOwnerStrSID: WideString;
    FOwnerName: WideString;
    FPriorityClass: DWORD;
    FCountThreads: DWORD;
    FCountModules: DWORD;
    FCreationTime: TFileTime;
    FKernelTime: TFileTime;
    FUserTime: TFileTime;
    function GetModuleFilename: WideString;
    function GetModulePath: WideString;
    function GetProcID: DWORD;
    function GetParentProcID: DWORD;
    function GetPOwnerSID: PSID;
    function GetOwnerSIDStr: WideString;
    function GetOwnerName: WideString;
    function GetPriorityClass: DWORD;
    function GetCountThreads: DWORD;
    function GetCountModules: DWORD;
    function GetCreationTime: TFileTime;
    function GetKernelTime: TFileTime;
    function GetUserTime: TFileTime;
    function InitOwnerName: WideString;
    function InitCountModules: DWORD;
    function InitCountThreads: DWORD;
    function InitModulePath: WideString;
  public
    constructor Create(PID: DWORD);
    property ModuleFilename: WideString read GetModuleFilename;
    property ModulePath: WideString read GetModulePath;
    property ProcID: DWORD read GetProcID;
    property ParentProcID: DWORD read GetParentProcID;
    property POwnerSID: PSID read GetPOwnerSID;
    property OwnerSIDStr: WideString read GetOwnerSIDStr;
    property OwnerName: WideString read GetOwnerName;
    property ProcessPriority: DWORD read GetPriorityClass;
    property CountThreads: DWORD read GetCountThreads;
    property CountModules: DWORD read GetCountModules;
    property CreationTime: TFileTime read GetCreationTime;
    property KernelTime: TFileTime read GetKernelTime;
    property UserTime: TFileTime read GetUserTime;
  end;

  TProcessList = class(Tobject)
  private
    FProcessList: TList;
    FPreviousDebugState: Boolean;
    FDebugPrivilegesEnabled: Boolean;
    function GetItem(Index: Integer): TProcess;
    procedure SetItem(Index: Integer; Process: TProcess);
    function GetCount: Integer;
  public
    constructor Create(EnableDebugPrivilege: Boolean);
    destructor Destroy; override;
    procedure Add(Process: TProcess);
    procedure Delete(Index: Integer);
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TProcess read GetItem write SetItem;
    procedure EnableDebugPrivileges;
    procedure EnumProcesses;
    procedure KillProcess(PID: DWORD; Wait: DWORD);
  end;

function GetSecurityInfo(handle: THandle; ObjectType: DWord; SecurityInfo: SECURITY_INFORMATION; ppsidOwner: PSID;
  ppsidGroup: PSID; ppDacl: PACL; ppSacl: PACL; ppSecurityDescriptor: PSECURITY_DESCRIPTOR): DWORD; stdcall; external
'advapi32.dll';
function ConvertSidToStringSid(SID: PSID; var StringSid: PWideChar): Boolean; stdcall;
external 'advapi32.dll' name 'ConvertSidToStringSidW';
function ConvertStringSidToSid(StringSid: PWideChar; var Sid: PSID): Boolean; stdcall; external 'advapi32.dll' name
'ConvertStringSidToSidW';

implementation

function FormatW(const S: WideString; const Args: array of const): WideString;
var
  StrBuffer2        : array[0..1023] of WideChar;
  A                 : array[0..15] of LongWord;
  i                 : Integer;
begin
  for i := High(Args) downto 0 do
    A[i] := Args[i].VInteger;
  wvsprintfW(@StrBuffer2, PWideChar(S), @A);
  Result := PWideChar(@StrBuffer2);
end;

function SysErrorMessage(ErrorCode: Integer): WideString;
var
  Len               : Integer;
  Buffer            : array[0..255] of WideChar;
begin
  Len := FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_ARGUMENT_ARRAY,
    nil, ErrorCode, 0, Buffer, SizeOf(Buffer), nil);
  SetString(Result, Buffer, Len);
end;

function SidToString(ASID: PSID): WideString;
var
  sDummy            : PWideChar;
begin
  ConvertSidToStringSid(ASID, sDummy);
  Result := string(sDummy);
end;

function StrSIDToName(const StrSID: Widestring; var Name: WideString; var SIDType: DWORD): Boolean;
var
  SID               : PSID;
  Buffer, Temp      : PWideChar;
  NameLen, TempLen  : Cardinal;
  succes            : Boolean;
begin
  SID := nil;
  succes := ConvertStringSIDToSID(PWideChar(StrSID), SID);
  if succes then
  begin
    NameLen := 0;
    TempLen := 0;
    LookupAccountSidW(nil, SID, nil, NameLen, nil, TempLen, SIDType);
    if NameLen > 0 then
    begin
      GetMem(Buffer, NameLen * sizeOf(WideChar));
      GetMem(Temp, TempLen * sizeof(WideChar));
      try
        succes := LookupAccountSidW(nil, SID, Buffer, NameLen, Temp, TempLen, SIDType);
        if succes then
        begin
          Name := WideString(Buffer);
        end;
      finally
        FreeMem(Buffer);
        FreeMem(Temp);
      end;
    end;
    LocalFree(Cardinal(SID));
  end;
  result := succes;
end;

function EnablePrivilege(const Privilege: string; fEnable: Boolean; out PreviousState: Boolean): Boolean;
var
  ok                : Boolean;
  Token             : THandle;
  NewState          : TTokenPrivileges;
  Luid              : TLargeInteger;
  PrevState         : TTokenPrivileges;
  Return            : DWORD;
begin
  PreviousState := True;
  if (GetVersion() > $80000000) then // Win9x
    Result := True
  else // WinNT
  begin
    ok := OpenProcessToken(GetCurrentProcess(), MAXIMUM_ALLOWED, Token);
    if ok then
    begin
      try
        ok := LookupPrivilegeValue(nil, PChar(Privilege), Luid);
        if ok then
        begin
          NewState.PrivilegeCount := 1;
          NewState.Privileges[0].Luid := Luid;
          if fEnable then
            NewState.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED
          else
            NewState.Privileges[0].Attributes := 0;
          ok := AdjustTokenPrivileges(Token, False, NewState, SizeOf(TTokenPrivileges), PrevState, Return);
          if ok then
          begin
            PreviousState := (PrevState.Privileges[0].Attributes and SE_PRIVILEGE_ENABLED <> 0);
          end;
        end;
      finally
        CloseHandle(Token);
      end;
    end;
    Result := ok;
  end;
end;

{ TProcess }

constructor TProcess.Create(PID: DWORD);
begin
  FProcID := PID;
  FModulePath := InitModulePath;
  FOwnerName := InitOwnerName; // Sets also FPOwnerSID, FOwnerStrSID
  FCountModules := InitCountModules;
  FCountThreads := InitCountThreads;
end;

function TProcess.GetModuleFilename: WideString;
begin
  Result := FModuleFilename;
end;

function TProcess.GetModulePath: WideString;
begin
  Result := FModulePath;
end;

function TProcess.GetOwnerName: WideString;
begin
  Result := FOwnerName;
end;

function TProcess.GetOwnerSIDStr: WideString;
begin
  Result := FOwnerStrSID;
end;

function TProcess.GetPOwnerSID: PSID;
begin
  Result := FPOwnerSID;
end;

function TProcess.GetPriorityClass: DWORD;
begin
  Result := FPriorityClass;
end;

function TProcess.GetCountThreads: DWORD;
begin
  Result := FCountThreads;
end;

function TProcess.GetCountModules: DWORD;
begin
  Result := FCountModules;
end;

function TProcess.GetProcID: DWORD;
begin
  Result := FProcID;
end;

function TProcess.GetParentProcID: DWORD;
begin
  Result := FParentProcID;
end;

function TProcess.GetCreationTime: TFileTime;
begin
  Result := FCreationTime;
end;

function TProcess.GetKernelTime: TFileTime;
begin
  Result := FKernelTime;
end;

function TProcess.GetUserTime: TFileTime;
begin
  Result := FUserTime;
end;

function TProcess.InitOwnerName: WideString;
var
  hProcess          : THandle;
  ppsidOwner        : PSID;
  SecDescriptor     : PSECURITY_DESCRIPTOR;
  err               : DWord;
  s                 : string;
  SIDType           : DWORD;
  Owner             : WideString;

const
  SE_UNKNOWN_OBJECT_TYPE: DWord = 0;
  SE_FILE_OBJECT    : DWord = 1;
  SE_SERVICE        : DWord = 2;
  SE_PRINTER        : DWord = 3;
  SE_REGISTRY_KEY   : DWord = 4;
  SE_LMSHARE        : DWord = 5;
  SE_KERNEL_OBJECT  : DWord = 6;
  SE_WINDOW_OBJECT  : DWord = 7;

begin
  Owner := '';
  hProcess := OpenProcess(PROCESS_QUERY_INFORMATION or GENERIC_READ, False, FProcID);
  if (hProcess <> 0) then
  begin
    err := GetSecurityInfo(hProcess, SE_KERNEL_OBJECT, OWNER_SECURITY_INFORMATION, @ppsidOwner, nil, nil, nil,
      @SecDescriptor);
    if (err = 0) then
    begin
      s := SidToString(ppsidOwner);
      FOwnerStrSID := s;
      FPOwnerSID := ppsidOwner;
      StrSIDToName(s, Owner, SIDType);
      LocalFree(Cardinal(SecDescriptor));
    end;
    CloseHandle(hProcess);
  end;
  Result := Owner;
end;

function TProcess.InitCountModules: DWORD;
var
  hProcess          : THandle;
  ModuleList        : array[0..1024] of DWORD;
  cbNeeded          : DWORD;
begin
  cbNeeded := 0;
  hProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, FProcID);
  if hProcess <> 0 then
  begin
    if EnumProcessModules(hProcess, @ModuleList, SizeOf(ModuleList), cbNeeded) then
    begin
      Result := cbNeeded div SizeOf(DWORD);
    end
    else
    begin
      Result := 0;
    end;
    CloseHandle(hProcess);
  end
  else
  begin
    Result := 0;
  end;
end;

function TProcess.InitModulePath: WideString;
var
  hSnapShot         : Thandle;
  hModuleSnapShot   : THandle;
  pe32              : TProcessEntry32W;
  me32              : TModuleEntry32W;
begin
  hSnapShot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, FProcID);
  if hSnapShot <> INVALID_HANDLE_VALUE then
  begin
    pe32.dwSize := SizeOf(TProcessEntry32W);
    if not Process32FirstW(hSnapShot, pe32) then
    begin
      CloseHandle(hSnapShot);
      raise TMpuProcToolException.Create(SysErrorMessage(GetLastError), GetLastError);
    end
    else
    begin
      if FProcID <> 0 then // Process 0 is no real process!
      begin
        hModuleSnapShot := CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, FProcID);
        if hModuleSnapShot <> INVALID_HANDLE_VALUE then
        begin
          me32.dwSize := SizeOf(TModuleEntry32W);
          if Module32FirstW(hModuleSnapShot, me32) then
          begin
            Result := me32.szExePath;
          end
          else
          begin
            Result := '';
            CloseHandle(hModuleSnapShot);
          end;
          CloseHandle(hModuleSnapShot);
        end
        else
          Result := '';
      end;
    end;
    CloseHandle(hSnapShot);
  end
  else
    raise TMpuProcToolException.Create(SysErrorMessage(GetLastError), GetLastError);
end;


function TProcess.InitCountThreads: DWORD;
var
  hSnapShot         : Thandle;
  pe32              : TProcessEntry32W;
begin
  Result := 0;
  hSnapShot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if hSnapShot <> INVALID_HANDLE_VALUE then
  begin
    pe32.dwSize := SizeOf(TProcessEntry32W);
    if not Process32FirstW(hSnapShot, pe32) then
    begin
      CloseHandle(hSnapShot);
      raise TMpuProcToolException.Create(SysErrorMessage(GetLastError), GetLastError);
    end
    else
    repeat
      if FProcID = pe32.th32ProcessID then
      begin
        Result := pe32.cntThreads;
        Break;
      end;
    until not Process32NextW(hSnapShot, pe32);
    CloseHandle(hSnapShot);
  end
  else
    raise TMpuProcToolException.Create(SysErrorMessage(GetLastError), GetLastError);
end;

{ TMpuProcToolException }

constructor TMpuProcToolException.Create(const msg: WideString);
begin
  FMsg := msg;
  FCode := DWord(-1);
end;

constructor TMpuProcToolException.Create(const msg: WideString; Errorcode: DWord);
begin
  FMsg := msg;
  FCode := Errorcode;
end;

constructor TMpuProcToolException.CreateFmt(Msg: WideString; const Args: array of TVarRec);
begin
  Create(FormatW(Msg, Args));
end;

{ TProcessList }

procedure TProcessList.Add(Process: TProcess);
begin
  FProcessList.Add(Process);
end;

constructor TProcessList.Create(EnableDebugPrivilege: Boolean);
begin
  FProcessList := TList.Create;
  if EnableDebugPrivilege then
    EnableDebugPrivileges;
end;

procedure TProcessList.Delete(Index: Integer);
begin
  // destroy object
  TObject(FProcessList.Items[Index]).Free;
  // delete object from the list
  FProcessList.Delete(Index);
end;

destructor TProcessList.Destroy;
var
  i                 : Integer;
begin
  if FProcessList.Count > 0 then
  begin
    for i := FProcessList.Count - 1 downto 0 do
    begin
      TObject(FProcessList.Items[i]).Free;
    end;
  end;
  FProcessList.Free;

  if FDebugPrivilegesEnabled then
    EnablePrivilege('SeDebugPrivilege', FPreviousDebugState, FPreviousDebugState);
  inherited;
end;

procedure TProcessList.EnableDebugPrivileges;
begin
  if EnablePrivilege('SeDebugPrivilege', True, FPreviousDebugState) then
    FDebugPrivilegesEnabled := True
  else
    raise TMpuProcToolException.Create(SysErrorMessage(GetLastError), GetLastError);
end;

//procedure TProcessList.EnumProcesses;
//var
//  hSnapShot         : Thandle;
//  hModuleSnapShot   : THandle;
//  pe32              : TProcessEntry32W;
//  me32              : TModuleEntry32W;
//  Process           : TProcess;
//begin
//  hSnapShot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
//  if hSnapShot <> INVALID_HANDLE_VALUE then
//  begin
//    pe32.dwSize := SizeOf(TProcessEntry32W);
//    if not Process32FirstW(hSnapShot, pe32) then
//    begin
//      CloseHandle(hSnapShot);
//      raise TMpuProcToolException.Create(SysErrorMessage(GetLastError), GetLastError);
//    end;
//    repeat
//      Process := TProcess.Create(pe32.th32ProcessID);
//      Process.FParentProcID := pe32.th32ParentProcessID;
//      Process.FModuleFilename := pe32.szExeFile;
//      Process.FPriorityClass := pe32.pcPriClassBase;
//      Process.FCountThreads := pe32.cntThreads;
//      if pe32.th32ProcessID <> 0 then  // Process 0 is no real process!
//      begin
//        hModuleSnapShot := CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, pe32.th32ProcessID);
//        if hModuleSnapShot <> INVALID_HANDLE_VALUE then
//        begin
//          me32.dwSize := SizeOf(TModuleEntry32W);
//          if Module32FirstW(hModuleSnapShot, me32) then
//          begin
//            Process.FModulePath := me32.szExePath;
//          end
//          else
//          begin
//            Process.FModulePath := '';
//            CloseHandle(hModuleSnapShot);
//          end;
//          CloseHandle(hModuleSnapShot);
//        end
//        else
//          Process.FModulePath := '';
//      end;
//
//      FProcessList.Add(Process);
//    until not Process32NextW(hSnapShot, pe32);
//  end
//  else
//    raise TMpuProcToolException.Create(SysErrorMessage(GetLastError), GetLastError);
//end;

procedure TProcessList.EnumProcesses;
const
  BUF_SIZE          = $10000;
var
  ProcListBuffer    : Pointer;
  BufSize           : Cardinal;
  Status            : Integer;
  OffSet            : ULONG;
  ProcessInfo       : PSYSTEM_PROCESS_INFORMATION;
  Process           : TProcess;
begin
  BufSize := BUF_SIZE;
  repeat
    GetMem(ProcListBuffer, BufSize);
    Status := NtQuerySystemInformation(SYSTEMPROCESSINFORMATION, ProcListBuffer, BufSize, nil);
    if Status = STATUS_INFO_LENGTH_MISMATCH then // Buffer too small, increase buffer size
    begin
      FreeMem(ProcListBuffer);
      Inc(BufSize, BUF_SIZE);
    end
    else if Status < 0 then
      raise TMpuProcToolException.Create(SysErrorMessage(GetLastError), GetLastError);
  until Status >= 0;
  // Process list successfully retrieved, walk the entries
  OffSet := 0;
  ProcessInfo := PSYSTEM_PROCESS_INFORMATION(ProcListBuffer);
  repeat
    ProcessInfo := PSYSTEM_PROCESS_INFORMATION(Cardinal(ProcessInfo) + OffSet);
    OffSet := ProcessInfo.NextEntryOffset;
    Process := TProcess.Create(ProcessInfo.UniqueProcessId);
    if ProcessInfo.ImageName.Length > 0 then
      Process.FModuleFilename := TUnicode_String(ProcessInfo.ImageName).Buffer
    else
      Process.FModuleFilename := '[System Idle Process]';
    Process.FParentProcID := ProcessInfo.InheritedFromUniqueProcessId;
    Process.FCreationTime.dwLowDateTime := ProcessInfo.CreateTime.LowPart;
    Process.FCreationTime.dwHighDateTime := ProcessInfo.CreateTime.HighPart;
    Process.FKernelTime.dwLowDateTime := ProcessInfo.KernelTime.LowPart;
    Process.FKernelTime.dwHighDateTime := ProcessInfo.KernelTime.HighPart;
    Process.FUserTime.dwLowDateTime := ProcessInfo.UserTime.LowPart;
    Process.FUserTime.dwHighDateTime := ProcessInfo.UserTime.HighPart;
    Process.FPriorityClass := ProcessInfo.BasePriority;
    FProcessList.Add(Process);
  until OffSet = 0;
  FreeMem(ProcListBuffer);
end;

function TProcessList.GetCount: Integer;
begin
  Result := FProcessList.Count;
end;

function TProcessList.GetItem(Index: Integer): TProcess;
begin
  Result := FProcessList.Items[Index];
end;

procedure TProcessList.KillProcess(PID: DWORD; Wait: DWORD);
var
  hProcess: THandle;
  wfso: DWORD;
begin
  hProcess := OpenProcess(SYNCHRONIZE or PROCESS_TERMINATE, False, PID);
  if hProcess <> 0 then
  begin
    if TerminateProcess(hProcess, 1) then
    begin
      // TerminateProcess returns immediately, verify if we have killed the process
      wfso := WaitForSingleObject(hProcess, Wait);
      if wfso = WAIT_FAILED then
        raise TMpuProcToolException.Create(SysErrorMessage(GetLastError), GetLastError);
    end
    else
      raise TMpuProcToolException.Create(SysErrorMessage(GetLastError), GetLastError);
  end
  else
    raise TMpuProcToolException.Create(SysErrorMessage(GetLastError), GetLastError);
end;

procedure TProcessList.SetItem(Index: Integer; Process: TProcess);
begin
  FProcessList.Items[Index] := Process;
end;

end.

