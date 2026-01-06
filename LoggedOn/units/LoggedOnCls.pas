unit LoggedOnCls;

interface

uses
  Windows,
  WinSock,
  MpuTools,
  Exceptions,
  List,
  LoggedOnHelpers;

type
  TExceptionMode = (
    emOn = 0,
    emOff = 1
    );

type
  TLoggedOnUser = class(TObject)
  private
    FUsername: string;
    FLogonDomain: string;
    FLogonServer: string;
    function GetUsername: string;
    procedure SetUsername(const Value: string);
    function GetLogonDomain: string;
    procedure SetLogonDomain(const Value: string);
    function GetLogonServer: string;
    procedure SetLogonServer(const Value: string);
  public
    property Username: string read GetUsername write SetUsername;
    property LogonDomain: string read GetLogonDomain write SetLogonDomain;
    property LogonServer: string read GetLogonServer write SetLogonServer;
  end;

  TLoggedOnUserCollection = class(TObject)
  private
    UserList: TList;
    function GetItem(Index: Integer): TLoggedOnUser;
    procedure SetItem(Index: Integer; LoggedOnUser: TLoggedOnUser);
  public
    constructor Create;
    destructor Destroy; override;
    property Items[Index: Integer]: TLoggedOnUser read GetItem write SetItem;
    procedure Add(LoggedOnUser: TLoggedOnUser);
    function Count: Integer;
    class function GetAllUsers(Machine: WideString; ExceptionMode: TExceptionMode): TLoggedOnUserCollection;
  end;

  TComputer = class(TObject)
  private
    FName: string;
    FLanGroup: string;
    FIP: string;
    FMAC: string;
    FOS: string;
    FComment: String;
    FToD: TTimeOfDayInfo;
    FLoggedOnUsers: TLoggedOnUserCollection;
    function GetName: string;
    procedure SetName(const Value: string);
    function GetLanGroup: string;
  	procedure SetLanGroup(Value: String);
    function GetIP: string;
    procedure SetIP(Value: string);
    function GetMAC: string;
    procedure SetMAC(value: String);
    function GetOS: string;
    procedure SetOS(const Value: string);
    function GetComment: String;
    procedure SetComment(value: String);
    function GetTod: TTimeOfDayInfo;
    procedure SetToD(value: TTimeOfDayInfo);
    function GetLoggedOnUsers: TLoggedOnUserCollection;
    procedure SetLoggedOnUsers(const Value: TLoggedOnUserCollection);
    procedure GetInfo;
  public
    constructor Create(MachineName: string);
    destructor Destroy; override;
    property Machine: string read GetName write SetName;
    property LanGroup: string read GetLanGroup write SetLanGroup;
    property IP: string read GetIP write SetIP;
    property MAC: string read GetMAC write SetMAC;
    property OS: string read GetOS write SetOS;
    property Comment: string read GetComment write SetComment;
    property ToD: TTimeOfDayInfo read GetTod write SetToD;
    property LoggedOnUsers: TLoggedOnUserCollection read GetLoggedOnUsers write SetLoggedOnUsers;
  end;

  TMachineCollection = class(TObject)
  private
    MachineList: TList;
    function GetItem(Index: Integer): TComputer;
    procedure SetItem(Index: Integer; Machine: TComputer);
  public
    constructor Create;
    destructor Destroy; override;
    property Items[Index: Integer]: TComputer read GetItem write SetItem;
    procedure Add(Machine: TComputer);
    function Count: Integer;
    class function GetAllMachines(const Domain: string; ExceptionMode: TExceptionMode): TMachineCollection;
  end;

const
  MAX_NAME_STRING   = 1024;
  MAX_PREFERRED_LENGTH = DWORD(-1);
  SV_TYPE_NT        = $00001000;
  SV_TYPE_WORKSTATION = $00000001;
  SV_TYPE_SERVER    = $00000002;
  SV_TYPE_SERVER_NT = $00008000;

type
  TWKSTA_USER_INFO_1 = packed record
    wkui1_username: LMSTR;
    wkui1_logon_domain: LMSTR;
    wkui1_oth_domains: LMSTR;
    wkui1_logon_server: LMSTR;
  end;
  PWKSTA_USER_INFO_1 = ^TWKSTA_USER_INFO_1;

  TSERVER_INFO_100 = packed record
    sv100_platform_id: INTEGER;
    sv100_name: PWideChar;
  end;
  PSERVER_INFO_100 = ^TSERVER_INFO_100;

function NetWkstaUserEnum(servername: PWideChar; level: DWORD; var buffer: Pointer; prefmaxlen: DWORD;
  var entriesread: DWORD; var totalentries: DWORD; var resumehandle: DWORD): NET_API_STATUS; stdcall;
function NetServerEnum(servername: PWideChar; level: DWORD; var bufptr: pointer; prefmaxlen: DWORD; var entriesread,
  totalentries: DWORD; servertype: DWORD; domain: PWideChar; var resumehandle: DWORD): NET_API_STATUS; stdcall;

implementation

const
  netapi32lib       = 'netapi32.dll';


function NetWkstaUserEnum; external netapi32lib name 'NetWkstaUserEnum';
function NetServerEnum; external netapi32lib name 'NetServerEnum';




function StrIComp(const Str1, Str2: PChar): Integer; assembler;
asm
        PUSH    EDI
        PUSH    ESI
        MOV     EDI,EDX
        MOV     ESI,EAX
        MOV     ECX,0FFFFFFFFH
        XOR     EAX,EAX
        REPNE   SCASB
        NOT     ECX
        MOV     EDI,EDX
        XOR     EDX,EDX
@@1:    REPE    CMPSB
        JE      @@4
        MOV     AL,[ESI-1]
        CMP     AL,'a'
        JB      @@2
        CMP     AL,'z'
        JA      @@2
        SUB     AL,20H
@@2:    MOV     DL,[EDI-1]
        CMP     DL,'a'
        JB      @@3
        CMP     DL,'z'
        JA      @@3
        SUB     DL,20H
@@3:    SUB     EAX,EDX
        JE      @@1
@@4:    POP     ESI
        POP     EDI
end;

function IsInList(List: TLoggedOnUserCollection; Username: string): Boolean;
var
  i                 : Integer;
begin
  result := False;
  for i := 0 to List.Count - 1 do
  begin
    if StrIComp(PChar(List.Items[i].FUsername), PChar(Username)) = 0 then
    begin
      Result := True;
      exit;
    end
  end;
end;

{ TLoggedOnUser }

function TLoggedOnUser.GetUsername: string;
begin
  Result := FUsername;
end;

procedure TLoggedOnUser.SetUsername(const Value: string);
begin
  FUsername := Value;
end;

function TLoggedOnUser.GetLogonDomain: string;
begin
  Result := FLogonDomain;
end;

procedure TLoggedOnUser.SetLogonDomain(const Value: string);
begin
  FLogonDomain := Value;
end;

function TLoggedOnUser.GetLogonServer: string;
begin
  Result := FLogonServer;
end;

procedure TLoggedOnUser.SetLogonServer(const Value: string);
begin
  FLogonServer := Value;
end;

{ TLoggedOnUserCollection }

constructor TLoggedOnUserCollection.Create;
begin
  inherited Create;
  UserList := TList.Create;
end;

destructor TLoggedOnUserCollection.Destroy;
var
  i                 : Integer;
begin
  for i := 0 to UserList.Count - 1 do
  begin
    TObject(UserList.Items[i]).Free;
  end;
  UserList.Free;
  inherited;
end;

function TLoggedOnUserCollection.GetItem(Index: Integer): TLoggedOnUser;
begin
  Result := UserList.Items[Index];
end;

procedure TLoggedOnUserCollection.SetItem(Index: Integer; LoggedOnUser: TLoggedOnUser);
begin
  if Assigned(UserList) then
    UserList.Items[Index] := LoggedOnUser;
end;

procedure TLoggedOnUserCollection.Add(LoggedOnUser: TLoggedOnUser);
begin
  UserList.Add(LoggedOnUser);
end;

function TLoggedOnUserCollection.Count: Integer;
begin
  Result := UserList.Count;
end;

class function TLoggedOnUserCollection.GetAllUsers(Machine: WideString; ExceptionMode: TExceptionMode):
  TLoggedOnUserCollection;
var
  err               : NET_API_STATUS;
  bufPtr            : Pointer;
  entriesread       : DWORD;
  totalentries      : DWORD;
  resumehandle      : DWORD;
  pCurrent          : PWKSTA_USER_INFO_1;
  i                 : Integer;
  LoggedOnUser      : TLoggedOnUser;

  // Taken from Assarbads LoggedOn2: http://www.assarbad.net
  // Modified for  LoggedOnCls classes

  procedure GetLocalLogons(const ServerName: string; UserCollection: TLoggedOnUserCollection);
  var
    userName,
      domainName    : array[0..MAX_NAME_STRING] of Char;
    subKeyName      : array[0..MAX_PATH] of Char;
    subKeyNameSize  : DWORD;
    index           : DWORD;
    userNameSize    : DWORD;
    domainNameSize  : DWORD;
    lastWriteTime   : FILETIME;
    usersKey        : HKEY;
    sid             : PSID;
    sidType         : SID_NAME_USE;
    authority       : SID_IDENTIFIER_AUTHORITY;
    subAuthorityCount: BYTE;
    authorityVal    : DWORD;
    revision        : DWORD;
    subAuthorityVal : array[0..7] of DWORD;
    User            : TLoggedOnUser;

    function getvals(s: string): integer;
    var
      i, j, k, l    : integer;
      tmp           : string;
    begin
      delete(s, 1, 2);
      j := pos('-', s);
      tmp := copy(s, 1, j - 1);
      val(tmp, revision, k);
      delete(s, 1, j);
      j := pos('-', s);
      tmp := copy(s, 1, j - 1);
      val('$' + tmp, authorityVal, k);
      delete(s, 1, j);
      i := 2;
      s := s + '-';
      for l := 0 to 7 do
      begin
        j := pos('-', s);
        if j > 0 then
        begin
          tmp := copy(s, 1, j - 1);
          val(tmp, subAuthorityVal[l], k);
          delete(s, 1, j);
          inc(i);
        end
        else
          break;
      end;
      result := i;
    end;

  begin
    revision := 0;
    authorityVal := 0;
    FillChar(subAuthorityVal, SizeOf(subAuthorityVal), #0);
    FillChar(userName, SizeOf(userName), #0);
    FillChar(domainName, SizeOf(domainName), #0);
    FillChar(subKeyName, SizeOf(subKeyName), #0);
    if ServerName <> '' then
    begin
      usersKey := 0;
      if (RegConnectRegistry(pchar(ServerName), HKEY_USERS, usersKey) <> 0) then
        Exit;
    end
    else
    begin
      if (RegOpenKey(HKEY_USERS, nil, usersKey) <> ERROR_SUCCESS) then
        Exit;
    end;
    index := 0;
    subKeyNameSize := SizeOf(subKeyName);
    while (RegEnumKeyEx(usersKey, index, subKeyName, subKeyNameSize, nil, nil, nil, @lastWriteTime) = ERROR_SUCCESS) do
    begin
      if (lstrcmpi(subKeyName, '.default') <> 0) and (Pos('Classes', string(subKeyName)) = 0) then
      begin
        subAuthorityCount := getvals(subKeyName);
        if (subAuthorityCount >= 3) then
        begin
          subAuthorityCount := subAuthorityCount - 2;
          if (subAuthorityCount < 2) then
            subAuthorityCount := 2;
          authority.Value[5] := PByte(@authorityVal)^;
          authority.Value[4] := PByte(DWORD(@authorityVal) + 1)^;
          authority.Value[3] := PByte(DWORD(@authorityVal) + 2)^;
          authority.Value[2] := PByte(DWORD(@authorityVal) + 3)^;
          authority.Value[1] := 0;
          authority.Value[0] := 0;
          sid := nil;
          userNameSize := MAX_NAME_STRING;
          domainNameSize := MAX_NAME_STRING;
          if AllocateAndInitializeSid(authority, subAuthorityCount, subAuthorityVal[0], subAuthorityVal[1],
            subAuthorityVal[2], subAuthorityVal[3], subAuthorityVal[4], subAuthorityVal[5], subAuthorityVal[6],
            subAuthorityVal[7], sid) then
          begin
            if LookupAccountSid(Pchar(ServerName), sid, userName, userNameSize, domainName, domainNameSize, sidType)
              then
            begin
              if not IsInList(UserCollection, userName) then
              begin
                User := TLoggedOnUser.Create;
                User.FUsername := string(userName) + '*';
                User.FLogonDomain := string(domainName);
                UserCollection.Add(User);
              end;
            end;
          end;
          if Assigned(sid) then
            FreeSid(sid);
        end;
      end;
      subKeyNameSize := SizeOf(subKeyName);
      Inc(index);
    end;
    RegCloseKey(usersKey);
  end;

begin
  Result := nil;
  bufPtr := nil;
  resumehandle := 0;
  try
    err := NetWkstaUserEnum(PWideChar(WideString(Machine)), 1, bufPtr, MAX_PREFERRED_LENGTH, entriesread, totalentries,
      resumehandle);
    if err = NERR_SUCCESS then
    begin
      Result := TLoggedOnUserCollection.Create;
      pCurrent := bufPtr;
      for i := 0 to totalentries - 1 do
      begin
        // Do not add machines themselves
        if copy(string(pCurrent.wkui1_username), length(string(pcurrent.wkui1_username)), 1) <> '$' then
        begin
          LoggedOnUser := TLoggedOnUser.Create;
          LoggedOnUser.Username := pCurrent.wkui1_username;
          LoggedOnUser.FLogonDomain := pCurrent.wkui1_logon_domain;
          LoggedOnUser.FLogonServer := pCurrent.wkui1_logon_server;
            // Avoid multiple entries. See:
            // Note that since the NetWkstaUserEnum function lists entries for service and batch logons, as well as for
            // interactive logons, the function can return entries for users who have logged off a workstation.
          if not IsInList(Result, LoggedOnUser.Username) then
            Result.Add(LoggedOnUser);
        end;
        Inc(pCurrent);
      end;
    end
    else
    begin
      // Only raise exception when we are scanning a single machine
      // Set ScanMode to smMachine only when scanning a single machine
      if ExceptionMode = emOn then
        raise ENetAPIError.Create(err);
    end;
    if not Assigned(result) then
      Result := TLoggedOnUserCollection.Create;
    GetLocalLogons(string(Machine), Result);
  finally
    NetApiBufferFree(bufPtr);
  end;
end;

{ TMachine }

constructor TComputer.Create(MachineName: string);
begin
  inherited Create;
  Self.Machine := MachineName;
  GetInfo;
end;

destructor TComputer.Destroy;
begin
  FLoggedOnUsers.Free;
  inherited;
end;

function TComputer.GetMAC: string;
begin
  Result := FMAC;
end;

function TComputer.GetName: string;
begin
  Result := FName;
end;

procedure TComputer.SetMAC(value: String);
begin
  FMAC := value;
end;

procedure TComputer.SetName(const Value: string);
begin
  FName := Value;
end;

function TComputer.GetComment: String;
begin
  Result := FComment;
end;

procedure TComputer.GetInfo;
begin
  Self.OS := GetComputerOS(Self.Machine);
  Self.Comment := GetComputerCommentW(Self.Machine);
  Self.LanGroup := GetComputerLanGroup(Self.Machine);
  Self.IP := GetComputerIP(Self.Machine);
  Self.MAC := GetComputerMAC(Self.IP);
  Self.ToD := GetComputerTimeOfDay(Self.Machine)
end;

function TComputer.GetIP: string;
begin
  Result := FIP;
end;

procedure TComputer.SetComment(value: String);
begin
  FComment := Value;
end;

procedure TComputer.SetIP(Value: string);
begin
  FIP:= Value;
end;

function TComputer.GetOS: string;
begin
  Result := FOS;
end;

function TComputer.GetTod: TTimeOfDayInfo;
begin
  Result := FToD;
end;

procedure TComputer.SetOS(const Value: string);
begin
  FOS := Value;
end;

procedure TComputer.SetToD(value: TTimeOfDayInfo);
begin
  FToD := value;
end;

function TComputer.GetLanGroup: string;
begin
  Result := FLanGroup;
end;

function TComputer.GetLoggedOnUsers: TLoggedOnUserCollection;
begin
  Result := FLoggedOnUsers;
end;

procedure TComputer.SetLanGroup(Value: String);
begin
  FLanGroup := Value;
end;

procedure TComputer.SetLoggedOnUsers(const Value: TLoggedOnUserCollection);
begin
  FLoggedOnUsers := Value;
end;

{ TMachineCollection }

constructor TMachineCollection.Create;
begin
  inherited Create;
  MachineList := TList.Create;
end;

destructor TMachineCollection.Destroy;
var
  i                 : Integer;
begin
  for i := 0 to MachineList.Count - 1 do
  begin
    TObject(MachineList.Items[i]).Free;
  end;
  MachineList.Free;
  inherited;
end;

function TMachineCollection.GetItem(Index: Integer): TComputer;
begin
  Result := MachineList.Items[Index];
end;

procedure TMachineCollection.SetItem(Index: Integer; Machine: TComputer);
begin
  if Assigned(MachineList) then
    MachineList.Items[Index] := Machine;
end;

procedure TMachineCollection.Add(Machine: TComputer);
begin
  MachineList.Add(Machine);
end;

function TMachineCollection.Count: Integer;
begin
  Result := MachineList.Count;
end;

class function TMachineCollection.GetAllMachines(const Domain: string; ExceptionMode: TExceptionMode):
  TMachineCollection;
var
  err               : NET_API_STATUS;
  bufPtr            : Pointer;
  entriesread       : DWORD;
  totalentries      : DWORD;
  resumehandle      : DWORD;
  pCurrent          : PSERVER_INFO_100;
  i                 : Integer;
  Machine           : TComputer;
begin
  Result := nil;
  bufPtr := nil;
  resumehandle := 0;
  try
    err := NetServerEnum(nil, 100, bufPtr, MAX_PREFERRED_LENGTH, entriesread, totalentries, SV_TYPE_NT or
      SV_TYPE_WORKSTATION or SV_TYPE_SERVER or SV_TYPE_SERVER_NT, PWideChar(WideString(Domain)),
      resumehandle);
    if err = NERR_SUCCESS then
    begin
      Result := TMachineCollection.Create;
      pCurrent := bufPtr;
      for i := 0 to totalentries - 1 do
      begin
        Machine := TComputer.Create(pCurrent.sv100_name);
        Result.Add(Machine);
        Machine.LoggedOnUsers := TLoggedOnUserCollection.GetAllUsers(Machine.Machine, emOff);
        Inc(pCurrent);
      end;
    end
    else
      raise ENetAPIError.Create(err);
  finally
    NetApiBufferFree(bufPtr);
  end;
end;

end.
