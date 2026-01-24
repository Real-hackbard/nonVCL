unit MSysUtils;

interface

uses
  Windows,
  ShlObj,
  ActiveX;

var
  IsWindows2000    : boolean = false;
  IsWindowsXP      : boolean = false;
  IsWindowsXPSp2   : boolean = false;
  IsWindowsVista   : boolean = false;



  function FileExists(const Filename: string): boolean;
  function DirectoryExists(const Directory: string): boolean;
  function ExtractFileDrive(const szFilename: string): string;
  function ExtractFilePath(const szFilename: string): string;
  function ExtractFileName(const szFilename: string): string;
  function CutFileExt(const szFilename: string): string;
  function ChangeFileExt(const szFileName, szNewExt: string): string;
  function FileSearch(const Name, DirList: string): string;
  function ExpandEnvStr(const szInput: string): string;

  function GetTempDir: string;
  function CreateTempFilename(const FilePrefix: string;
    out TempFilename: string): boolean;
  function WinExec32AndWait(const Cmd: string; const CmdShow: Integer):
    Cardinal;

  function StrToIntDef(const s: string; const i: integer): integer;
  function IntToStr(const i: integer): string;
  function UpperCase(const s: string): string;
  function LowerCase(const s: string): string;

  function CreateComObject(const ClassID: TGUID;
    var OleResult: HRESULT): IUnknown;
  function GetSpecialPath(PathID: integer): string;
  procedure FreeItemIdList(var pidl: PItemIdList);
  procedure FreeAndNil(var Obj);

  function Format(fmt: string; params: array of const): string;
  function SystemErrorMsg(const dwErrorVal: dword = 0): string;
  function GetFileInfo(const FileName, BlockKey: string): string;
  function GetFileVersionString(const FileName: string): string;
  function CreateFolderShortCut(const DestinationPath, Folder: string):
    boolean;

  function IsAdmin: LongBool;
  function DeleteFileDuringNextSystemBoot(aFileName: string): Boolean;
  procedure SetPrivilege(const PrivilegeName: pchar);

  function DoesObjectExist(const ClassID: TGUID): boolean;
  function ExtractResToTemp(const Module: HINST; ResourceName,
    ResourceType: pchar; out TempFileName: string): boolean;

  function IsManifestAvailable(const FileName: string): boolean;



  // Shell helper functions

const
  // Return flags for PathGetCharType
  GCT_INVALID             = $0000;
  GCT_LFNCHAR             = $0001;
  GCT_SHORTCHAR           = $0002;
  GCT_WILD                = $0004;
  GCT_SEPARATOR           = $0008;

  function PathAddBackslash(lpszPath: PAnsiChar): PAnsiChar; stdcall;
  function PathAddExtension(lpszPath, lpszExtension: PAnsiChar): bool; stdcall;
  function PathAppend(pszPath, pszMore: PAnsiChar): bool; stdcall;
  function PathBuildRoot(pszRoot: PAnsiChar; iDrive: integer): PAnsiChar;
    stdcall;
  function PathCanonicalize(lpszDest, lpszSrc: PAnsiChar): bool; stdcall;
  function PathCombine(lpszDest, lpszDir, lpszFile: PAnsiChar): PAnsiChar;
    stdcall;
  function PathCompactPath(dc: HDC; pszPath: PAnsiChar; dx: UINT): bool;
    stdcall;
  function PathCompactPathEx(pszOut, pszSrc: PAnsiChar; cchMax: UINT;
    dwFlags: dword): bool; stdcall;
  function PathCommonPrefix(pszFile1, pszFile2, achPath: PAnsiChar): integer;
    stdcall;
  function PathFileExists(pszPath: PAnsiChar): bool; stdcall;
  function PathFindExtension(pszPath: PAnsiChar): PAnsiChar; stdcall;
  function PathFindFileName(pszPath: PAnsiChar): PAnsiChar; stdcall;
  function PathFindNextComponent(pszPath: PAnsiChar): PAnsiChar; stdcall;
  function PathFindOnPath(pszPath, ppszOtherDirs: PAnsiChar): bool; stdcall;
  function PathGetArgs(pszPath: PAnsiChar): PAnsiChar; stdcall;
  function PathFindSuffixArray(pszPath: PAnsiChar;
    const apszSuffix: PAnsiChar; iArraySize: integer): PAnsiChar; stdcall;
  function PathIsLFNFileSpec(lpName: PAnsiChar): bool; stdcall;
  function PathGetCharType(ch: UCHAR): UINT; stdcall;
  function PathGetDriveNumber(pszPath: PAnsiChar): integer; stdcall;
  function PathIsDirectory(pszPath: PAnsiChar): bool; stdcall;
  function PathIsDirectoryEmpty(pszPath: PAnsiChar): bool; stdcall;
  function PathIsFileSpec(pszPath: PAnsiChar): bool; stdcall;
  function PathIsPrefix(pszPrefix, pszPath: PAnsiChar): bool; stdcall;
  function PathIsRelative(pszPath: PAnsiChar): bool; stdcall;
  function PathIsRoot(pszPath: PAnsiChar): bool; stdcall;
  function PathIsSameRoot(pszPath1, pszPath2: PAnsiChar): bool; stdcall;
  function PathIsUNC(pszPath: PAnsiChar): bool; stdcall;
  function PathIsNetworkPath(pszPath: PAnsiChar): bool; stdcall;
  function PathIsUNCServer(pszPath: PAnsiChar): bool; stdcall;
  function PathIsUNCServerShare(pszPath: PAnsiChar): bool; stdcall;
  function PathIsContentType(pszPath, pszContentType: PAnsiChar): bool;
    stdcall;
  function PathIsURL(pszPath: PAnsiChar): bool; stdcall;
  function PathMakePretty(pszPath: PAnsiChar): bool; stdcall;
  function PathMatchSpec(pszFile, pszSpec: PAnsiChar): bool; stdcall;
  function PathParseIconLocation(pszIconFile: PAnsiChar): integer; stdcall;
  procedure PathQuoteSpaces(pszPath: PAnsiChar); stdcall;
  function PathRelativePathTo(pszPath, pszFrom: PAnsiChar;
    dwAttrFrom: dword; pszTo: PAnsiChar; dwAttrTo: dword): bool; stdcall;
  procedure PathRemoveArgs(pszPath: PAnsiChar); stdcall;
  function PathRemoveBackslash(pszPath: PAnsiChar): PAnsiChar; stdcall;
  procedure PathRemoveBlanks(pszPath: PAnsiChar); stdcall;
  procedure PathRemoveExtension(pszPath: PAnsiChar); stdcall;
  function PathRemoveFileSpec(pszPath: PAnsiChar): bool; stdcall;
  function PathRenameExtension(pszPath, pszExt: PAnsiChar): bool; stdcall;
  function PathSearchAndQualify(pszPath, pszBuf: PAnsiChar; cchBuf: UINT):
    bool; stdcall;
  procedure PathSetDlgItemPath(dlg: HWND; id: integer; pszPath: PAnsiChar);
    stdcall;
  function PathSkipRoot(pszPath: PAnsiChar): PAnsiChar; stdcall;
  procedure PathStripPath(pszPath: PAnsiChar); stdcall;
  function PathStripToRoot(pszPath: PAnsiChar): bool; stdcall;
  procedure PathUnquoteSpaces(pszPath: PAnsiChar); stdcall;
  function PathMakeSystemFolder(pszPath: PAnsiChar): bool; stdcall;
  function PathUnmakeSystemFolder(pszPath: PAnsiChar): bool; stdcall;
  function PathIsSystemFolder(pszPath: PAnsiChar; dwAttrb: dword): bool;
    stdcall;
  procedure PathUndecorate(pszPath: PAnsiChar); stdcall;
  function PathUnExpandEnvStrings(pszPath, pszBuf: PAnsiChar; cchBuf: UINT):
    bool; stdcall;


//
// Extended OS Info
//
type
  POSVersionInfoA = ^TOSVersionInfoA;
  POSVersionInfoW = ^TOSVersionInfoW;
  POSVersionInfo = POSVersionInfoA;
  _OSVERSIONINFOA = record
    dwOSVersionInfoSize: DWORD;
    dwMajorVersion: DWORD;
    dwMinorVersion: DWORD;
    dwBuildNumber: DWORD;
    dwPlatformId: DWORD;
    szCSDVersion: array[0..127] of AnsiChar; { Maintenance string for PSS usage }
    wServicePackMajor,
    wServicePackMinor,
    wSuiteMask : word;
    wProductType,
    wReserved : byte;
  end;
  {$EXTERNALSYM _OSVERSIONINFOA}
  _OSVERSIONINFOW = record
    dwOSVersionInfoSize: DWORD;
    dwMajorVersion: DWORD;
    dwMinorVersion: DWORD;
    dwBuildNumber: DWORD;
    dwPlatformId: DWORD;
    szCSDVersion: array[0..127] of WideChar; { Maintenance string for PSS usage }
    wServicePackMajor,
    wServicePackMinor,
    wSuiteMask : word;
    wProductType,
    wReserved : byte;
  end;
  {$EXTERNALSYM _OSVERSIONINFOW}
  _OSVERSIONINFO = _OSVERSIONINFOA;
  TOSVersionInfoA = _OSVERSIONINFOA;
  TOSVersionInfoW = _OSVERSIONINFOW;
  TOSVersionInfo = TOSVersionInfoA;
  OSVERSIONINFOA = _OSVERSIONINFOA;
  {$EXTERNALSYM OSVERSIONINFOA}
  {$EXTERNALSYM OSVERSIONINFO}
  OSVERSIONINFOW = _OSVERSIONINFOW;
  {$EXTERNALSYM OSVERSIONINFOW}
  {$EXTERNALSYM OSVERSIONINFO}
  OSVERSIONINFO = OSVERSIONINFOA;

const
  {$EXTERNALSYM VERSIONINFOSIZEA}
  VERSIONINFOSIZEA  = sizeof(TOSVersionInfoA) -
    (sizeof(word) * 3) - (sizeof(byte) * 2);
  {$EXTERNALSYM VERSIONINFOSIZEW}
  VERSIONINFOSIZEW  = sizeof(TOSVersionInfoW) -
    (sizeof(word) * 3) - (sizeof(byte) * 2);
  {$EXTERNALSYM VERSIONINFOSIZE}
  VERSIONINFOSIZE   = VERSIONINFOSIZEA;


const
  //
  // RtlVerifyVersionInfo() os product type values
  //
  VER_NT_WORKSTATION                  = $0000001;
  VER_NT_DOMAIN_CONTROLLER            = $0000002;
  VER_NT_SERVER                       = $0000003;

  VER_SERVER_NT                       = $80000000;
  VER_WORKSTATION_NT                  = $40000000;
  VER_SUITE_SMALLBUSINESS             = $00000001;
  VER_SUITE_ENTERPRISE                = $00000002;
  VER_SUITE_BACKOFFICE                = $00000004;
  VER_SUITE_COMMUNICATIONS            = $00000008;
  VER_SUITE_TERMINAL                  = $00000010;
  VER_SUITE_SMALLBUSINESS_RESTRICTED  = $00000020;
  VER_SUITE_EMBEDDEDNT                = $00000040;
  VER_SUITE_DATACENTER                = $00000080;
  VER_SUITE_SINGLEUSERTS              = $00000100;
  VER_SUITE_PERSONAL                  = $00000200;
  VER_SUITE_BLADE                     = $00000400;
  VER_SUITE_EMBEDDED_RESTRICTED       = $00000800;
  VER_SUITE_SECURITY_APPLIANCE        = $00001000;


  function GetVersionExA(var lpVersionInformation: TOSVersionInfo): BOOL;
    stdcall;
  {$EXTERNALSYM GetVersionExA}
  function GetVersionExW(var lpVersionInformation: TOSVersionInfo): BOOL;
    stdcall;
  {$EXTERNALSYM GetVersionExW}
  function GetVersionEx(var lpVersionInformation: TOSVersionInfo): BOOL;
    stdcall;
  {$EXTERNALSYM GetVersionEx}


implementation

function FileExists(const Filename: string): boolean;
var
  Handle   : THandle;
  FindData : TWin32FindData;
begin
  Handle   := FindFirstFile(pchar(Filename),FindData);
  Result   := (Handle <> INVALID_HANDLE_VALUE);

  if(Result) then Windows.FindClose(Handle);
end;

function DirectoryExists(const Directory: string): boolean;
var
  Handle   : THandle;
  FindData : TWin32FindData;
begin
  Handle   := FindFirstFile(pchar(Directory),FindData);
  Result   := (Handle <> INVALID_HANDLE_VALUE) and
    (FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0);

  if(Handle <> INVALID_HANDLE_VALUE) then
    Windows.FindClose(Handle);
end;

function ExtractFileDrive(const szFilename: string): string;
var
  i : integer;
begin
  Result := '';
  i      := length(szFilename);
  while(i > 0) do
  begin
    if(szFileName[i] = ':') then
    begin
      Result := copy(szFilename,1,i);
      break;
    end;

    dec(i);
  end;
end;

function ExtractFilePath(const szFilename: string): string;
var
  i : integer;
begin
  Result := '';
  i      := length(szFileName);
  while(i > 0) do
  begin
    if(szFileName[i] = ':') or
      (szFileName[i] = '\') then
    begin
      Result := copy(szFileName,1,i);
      break;
    end;

    dec(i);
  end;
end;

function ExtractFileName(const szFilename: string): string;
var
  i : integer;
begin
  i := length(szFilename);
  while(i > 0) do
  begin
    if(szFilename[i] = '\') then
      break;

    dec(i);
  end;

  Result := copy(szFilename,i + 1,length(szFilename));
end;

function CutFileExt(const szFilename: string): string;
var
  i : integer;
begin
  i := length(szFilename);
  while(i > 0) do
  begin
    if(szFilename[i] = '.') then
      break;

    dec(i);
  end;

  if(i = 0) then Result := szFilename
    else Result := copy(szFilename,1,i-1);
end;

function ChangeFileExt(const szFileName, szNewExt: string): string;
begin
  Result := CutFileExt(szFileName);

  if(szNewExt[1] <> '.') then Result := Result + '.' + szNewExt
    else Result := Result + szNewExt;
end;

function FileSearch(const Name, DirList: string): string;
var
  I, P, L: Integer;
begin
  Result := Name;
  P      := 1;
  L      := length(DirList);

  while(true) do
  begin
    if(fileexists(Result)) then exit;

    while(P <= L) and (DirList[P] = ';') do inc(P);
    if(P > L) then break;

    I := P;
    while(P <= L) and (DirList[P] <> ';') do inc(P);

    Result   := copy(DirList,I,P-I);
    if not(Result[length(Result)] in[':','\']) then
      Result := Result + '\';

    Result := Result + Name;
  end;

  Result  := '';
end;

function ExpandEnvStr(const szInput: string): string;
const
  MAXSIZE = 32768;
begin
  SetLength(Result,MAXSIZE);
  SetLength(Result,ExpandEnvironmentStrings(pchar(szInput),
    @Result[1],length(Result)));
end;

// -----------------------------------------------------------------------------

function GetTempDir: string;
begin
  SetLength(Result,MAX_PATH);
  SetLength(Result,GetTempPath(length(Result),@Result[1]));
end;

function CreateTempFilename(const FilePrefix: string; out TempFilename: string):
  boolean;
begin
  SetLength(TempFilename,MAX_PATH + 1);
  Result := GetTempFileName(pchar(GetTempDir),pchar(FilePrefix),0,
    @TempFilename[1]) <> 0;
end;

// -----------------------------------------------------------------------------

function WinExec32AndWait(const Cmd: string; const CmdShow: Integer): Cardinal;
var
  si     : TStartupInfo;
  pi     : TProcessInformation;
begin
  Result := Cardinal($FFFFFFFF);

  ZeroMemory(@si,sizeof(si));
  si.cb          := sizeof(si);
  si.dwFlags     := STARTF_USESHOWWINDOW;
  si.wShowWindow := CmdShow;

  if(CreateProcess(nil,pchar(Cmd),nil,nil,false,NORMAL_PRIORITY_CLASS,
    nil,nil,si,pi)) then
  try
    WaitForInputIdle(pi.hProcess,INFINITE);
    if(WaitForSingleObject(pi.hProcess,INFINITE) = WAIT_OBJECT_0) then
    begin
{$IFDEF VER110}
      if(not GetExitCodeProcess(pi.hProcess,integer(Result))) then
{$ELSE}
      if(not GetExitCodeProcess(pi.hProcess,Result)) then
{$ENDIF}
      Result := Cardinal($FFFFFFFF);
    end;
  finally
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
  end;
end;

// -----------------------------------------------------------------------------

function StrToIntDef(const s: string; const i: integer): integer;
var
  code : integer;
begin
  Val(s,Result,code);
  if(code <> 0) then Result := i;
end;

function IntToStr(const i: integer): string;
begin
  Str(i,Result);
end;

function UpperCase(const s: string): string;
var
  i : integer;
begin
  Result := '';

  if(length(s) > 0) then
  begin
    SetLength(Result,length(s));
    for i := 1 to length(s) do
      Result[i] := UpCase(s[i]);
  end;
end;

function LowerCase(const s: string): string;
var
  i : integer;
begin
  Result := '';

  if(length(s) > 0) then
  begin
    SetLength(Result,length(s));
    for i := 1 to length(s) do
      case s[i] of
        'A'..'Z','Ä','Ö','Ü':
          Result[i] := CHR(BYTE(s[i]) + 32);
        else
          Result[i] := s[i];
      end;
  end;
end;


// -----------------------------------------------------------------------------

//
// "CreateComObject"
//   * taken from Borland's "ComObj.pas" unit
//   * modified to get the "OleResult"
//
function CreateComObject(const ClassID: TGUID;
  var OleResult : HRESULT): IUnknown;
begin
  OleResult := CoCreateInstance(ClassID,nil,CLSCTX_INPROC_SERVER or
    CLSCTX_LOCAL_SERVER,IUnknown,Result);
end;

function GetSpecialPath(PathID: integer): string;
var
  pm     : IMalloc;
  pidl   : PItemIdList;
  buf    : array[0..MAX_PATH]of char;
begin
  Result := '';
  pidl   := nil;

  if(SHGetMalloc(pm) = S_OK) and
    (SHGetSpecialFolderLocation(0,PathId,pidl) = S_OK) then
  try
    ZeroMemory(@buf,sizeof(buf));

    if(SHGetPathFromIdList(pidl,buf)) then
      SetString(Result,buf,lstrlen(buf));

    if(pidl <> nil) then pm.Free(pidl);
  finally
    pm := nil;
  end;
end;

procedure FreeItemIdList(var pidl: PItemIdList);
var
  pMalloc : IMalloc;
begin
  if(SHGetMalloc(pMalloc) = S_OK) then
  try
    pMalloc.Free(pidl);
    pidl    := nil;
  finally
    pMalloc := nil;
  end;
end;

procedure FreeAndNil(var Obj);
var
  Temp         : TObject;
begin
  Temp         := TObject(Obj);
  Pointer(Obj) := nil;
  Temp.Free;
end;


// -----------------------------------------------------------------------------

function Format(fmt: string; params: array of const): string;
var
  pdw1,
  pdw2 : PDWORD;
  i    : integer;
  pc   : PCHAR;
begin
  pdw1 := nil;

  if High(params) >= 0 then
    GetMem(pdw1, (High(params) + 1) * sizeof(Pointer));

  pdw2  := pdw1;
  for i := 0 to High(params) do
  begin
    pdw2^ := PDWORD(@params[i])^;
    inc(pdw2);
  end;

  pc := GetMemory(1024);
  if Assigned(pc) then
  try
    SetString(Result, pc, wvsprintf(pc, PCHAR(fmt), PCHAR(pdw1)));
  finally
    if (pdw1 <> nil) then FreeMem(pdw1);
    FreeMem(pc);
  end
  else
    Result := '';
end;


//
// Michael (Luckie) Puff
//
function SystemErrorMsg(const dwErrorVal: dword = 0): string;
var
  buf   : array[0..MAX_PATH]of char;
  dwVal : dword;
begin
  if(dwErrorVal = 0) then dwVal := GetLastError
    else dwVal := dwErrorVal;

  ZeroMemory(@buf,sizeof(buf));
  FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,nil,dwVal,0,buf,sizeof(buf),nil);
  SetString(Result,buf,lstrlen(buf));
end;


//
// base code by sakura (http://www.delphipraxis.net/post39547.html)
//
function GetFileInfo(const FileName, BlockKey: string): string;
var
  vis,
  dummy         : dword;
  vi,
  translation,
  ip            : pointer;
begin
  Result        := '';
  vis           := GetFileVersionInfoSize(pchar(FileName),dummy);
  if(vis > 0) then
  begin
    GetMem(vi,vis);
    try
      GetFileVersionInfo(pchar(Filename),0,vis,vi);
      if(vi = nil) then exit;

      // get language code
      VerQueryValue(vi,'\\VarFileInfo\\Translation',translation,vis);
      if(translation = nil) then exit;

      VerQueryValue(vi,
        pchar(Format('\\StringFileInfo\\%.4x%.4x\\%s',
          [LOWORD(longint(translation^)),HIWORD(longint(translation^)),
          BlockKey])),ip,vis);
      if(ip = nil) then exit;

      SetString(Result,pchar(ip),vis - 1);
    finally
      FreeMem(vi);
    end;
  end;
end;

function GetFileVersionString(const FileName: string): string;
const
  FormatStr = '%d.%d.%d.%d';
var
  vis,
  dummy     : dword;
  vi        : pointer;
  FixBuf    : PVSFixedFileInfo;
begin
  Result    := '';
  vis       := GetFileVersionInfoSize(pchar(FileName),dummy);
  if(vis > 0) then
  begin
    GetMem(vi,vis);
    try
      GetFileVersionInfo(pchar(FileName),0,vis,vi);
      if(vi = nil) then exit;

      VerQueryValue(vi,'\\',pointer(FixBuf),dummy);
      if(FixBuf = nil) then exit;

      Result := Format(FormatStr,
       [(FixBuf^.dwFileVersionMS and $FFFF0000) shr 16,
         FixBuf^.dwFileVersionMS and $0000FFFF,
        (FixBuf^.dwFileVersionLS and $FFFF0000) shr 16,
         FixBuf^.dwFileVersionLS and $0000FFFF]);
    finally
      FreeMem(vi);
    end;
  end;
end;

function CreateFolderShortCut(const DestinationPath, Folder: string):
  boolean;

  function CreateReadOnlyDir(const Path: string): boolean;
  begin
    // schreibgeschützten Ordner erzeugen, ...
    Result := (CreateDirectory(pchar(Path),nil)) and
      (SetFileAttributes(pchar(Path),FILE_ATTRIBUTE_READONLY)) and
    // ... & versteckte "desktop.ini" erzeugen
      (WritePrivateProfileString('.ShellClassInfo','CLSID2',
         '{0AFACED1-E828-11D1-9187-B532F1E9575D}',
         pchar(Path + '\desktop.ini'))) and
      (WritePrivateProfileString('.ShellClassInfo','Flags','2',
         pchar(Path + '\desktop.ini'))) and
      (SetFileAttributes(pchar(Path + '\desktop.ini'),
         FILE_ATTRIBUTE_HIDDEN or FILE_ATTRIBUTE_SYSTEM));
  end;

  function CreateComObject(const ClassID: TGUID;
    var OleResult : HRESULT): IUnknown;
  begin
    OleResult := CoCreateInstance(ClassID,nil,CLSCTX_INPROC_SERVER or
      CLSCTX_LOCAL_SERVER,IUnknown,Result);
  end;

var
  hr      : HRESULT;
  link    : IShellLink;
  pFile   : IPersistFile;
  pwcData : array[0..MAX_PATH]of widechar;
begin
  Result  := false;
  link    := nil;
  pFile   := nil;

  if(CoInitialize(nil) = S_OK) then
  try
    // Shortcut erzeugen
    link := CreateComObject(CLSID_ShellLink,hr) as IShellLink;
    if(hr = S_OK) and (link <> nil) then
    begin
      // Name für die Verknüpfung setzen
      ZeroMemory(@pwcData,sizeof(pwcData));
      if(StringToWideChar(DestinationPath + '\target.lnk',pwcData,
        sizeof(pwcData)) <> nil) then
      begin
        // Ordner erzeugen, ...
        if(CreateReadOnlyDir(DestinationPath)) then
        begin
          // Verknüpfungsziel setzen, ...
          link.SetPath(pchar(Folder));

          // ... & Verknüpfung erstellen
          pFile  := link as IPersistFile;
          if(pFile <> nil) then
            Result := (pFile.Save(pwcData,true) = S_OK);
        end;
      end;
    end;
  finally
    if(pFile <> nil) then pFile := nil;
    if(link <> nil) then link := nil;

    CoUninitialize;
  end;
end;


// -----------------------------------------------------------------------------

function GetAdminSid: PSID;
const
  // bekannte SIDs ... (WinNT.h)
  SECURITYNTAUTHORITY: TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));
  // bekannte RIDs ... (WinNT.h)
  SECURITYBUILTINDOMAINRID: DWORD = $00000020;
  DOMAINALIASRIDADMINS: DWORD = $00000220;
begin
  Result := nil;
  AllocateAndInitializeSid(SECURITYNTAUTHORITY,
    2,
    SECURITYBUILTINDOMAINRID,
    DOMAINALIASRIDADMINS,
    0,
    0,
    0,
    0,
    0,
    0,
    Result);
end;

function IsAdmin: LongBool;
var
  TokenHandle      : THandle;
  ReturnLength     : DWORD;
  TokenInformation : PTokenGroups;
  AdminSid         : PSID;
  Loop             : Integer;
  wv               : TOSVersionInfo;
begin
  ZeroMemory(@wv,sizeof(wv));
  wv.dwOSVersionInfoSize := sizeof(wv);
  GetVersionEx(wv);

  Result := (wv.dwPlatformId = VER_PLATFORM_WIN32_WINDOWS);

  if(wv.dwPlatformId = VER_PLATFORM_WIN32_NT) then
  begin
    TokenHandle := 0;
    if OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, TokenHandle) then
    try
      ReturnLength := 0;
      GetTokenInformation(TokenHandle, TokenGroups, nil, 0, ReturnLength);
      TokenInformation := GetMemory(ReturnLength);
      if Assigned(TokenInformation) then
      try
        if GetTokenInformation(TokenHandle, TokenGroups,
          TokenInformation, ReturnLength, ReturnLength) then
        begin
          AdminSid := GetAdminSid;
          for Loop := 0 to TokenInformation^.GroupCount - 1 do
          begin
            if EqualSid(TokenInformation^.Groups[Loop].Sid, AdminSid) then
            begin
              Result := True; break;
            end;
          end;

          FreeSid(AdminSid);
        end;
      finally
        FreeMemory(TokenInformation);
      end;
    finally
      CloseHandle(TokenHandle);
    end;
  end;
end;


//
// delete files during next reboot (code by sakura)
//
function DeleteFileDuringNextSystemBoot(aFileName: string): Boolean;
var
  ShortName,
  winini    : string;
  os        : TOSVersionInfo;
  ts        : array of string;
  f         : TextFile;
  i         : integer;
begin
  Result := False;

  // get OS version
  os.dwOSVersionInfoSize := sizeof(TOSVersionInfo);
  GetVersionEx(os);

  case os.dwPlatformId of
    // NT systems
    VER_PLATFORM_WIN32_NT:
      Result := MoveFileEx(pchar(aFileName),nil,
        MOVEFILE_REPLACE_EXISTING + MOVEFILE_DELAY_UNTIL_REBOOT);
    // 9x systems
    VER_PLATFORM_WIN32_WINDOWS:
      begin
        // get Windows folder
        SetLength(winini,MAX_PATH+1);
        SetLength(winini,GetWindowsDirectory(@winini[1],MAX_PATH+1));

        if(winini <> '') then
        begin
          if(winini[length(winini)] <> '\') then
            winini := winini + '\';
          winini   := winini + 'wininit.ini';

          // get short name of the given file
          SetLength(ShortName,MAX_PATH+1);
          SetLength(ShortName,
            GetShortPathName(@aFilename[1],@ShortName[1],MAX_PATH+1));

          if(ShortName <> '') then
          begin
            // add it to "wininit.ini" to delete
            // during next reboot
            SetLength(ts,0);

            {$I-}
            // get old file´s content
            AssignFile(f,winini);
            ReSet(f);
            if(IoResult = 0) then
            begin
              while(not eof(f)) do
              begin
                SetLength(ts,length(ts)+1);
                ReadLn(f,ts[length(ts)-1]);

                if(lstrcmpi('[rename]',pchar(ts[length(ts)-1])) = 0) then
                begin
                  SetLength(ts,length(ts)+1);
                  ts[length(ts)-1] := 'NUL='+ShortName;
                end;
              end;
              CloseFile(f);
            end;

            if(length(ts) = 0) then
            begin
              SetLength(ts,2);
              ts[0] := '[rename]';
              ts[1] := 'NUL='+ShortName;
            end;

            // re-create
            ReWrite(f);
            Result := (IoResult = 0);
            if(Result) then
            begin
              for i := 0 to length(ts) - 1 do
                WriteLn(f,ts[i]);

              CloseFile(f);
            end;
            {$I+}

            SetLength(ts,0);
          end;
        end;
      end;
    // only 9x and NT are supported
    else
      exit;
  end;
end;

procedure SetPrivilege(const PrivilegeName: pchar);
var
  os    : TOSVersionInfo;
  Token : THandle;
  tkp   : TTokenPrivileges;
begin
  ZeroMemory(@os,sizeof(os));
  os.dwOSVersionInfoSize := sizeof(os);

  if(GetVersionEx(os)) and
    (os.dwPlatformId = VER_PLATFORM_WIN32_NT) then
  begin
    // Code snippet from Peter J Haas
    // Thanks
    if(OpenProcessToken(GetCurrentProcess,
      TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY,Token)) then
    try
      // Get the LUID for the shutdown privilege.
      if(not LookupPrivilegeValue(nil,PrivilegeName,
        tkp.Privileges[0].Luid)) then exit;

      tkp.PrivilegeCount := 1;  // one privilege to set
      tkp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;

      // Get the shutdown privilege for this process.
      AdjustTokenPrivileges(Token,false,tkp,
        0,PTokenPrivileges(nil)^,PDWord(nil)^);

      // Cannot test the return value of AdjustTokenPrivileges.
      if(GetLastError <> ERROR_SUCCESS) then exit;
    finally
      CloseHandle(Token);
    end;
  end;
end;


// -----------------------------------------------------------------------------

function DoesObjectExist(const ClassID: TGUID): boolean;

  function GuidToString(const ClassID: TGUID): string;
  var
    p : PWideChar;
  begin
    Result := '';

    if(Succeeded(StringFromCLSID(ClassID,p))) then
    begin
      Result := p;
      CoTaskMemFree(p);
    end;
  end;

var
  reg    : HKEY;
  dwType,
  dwLen  : dword;
  s      : string;
begin
  Result := false;

  if(RegOpenKeyEx(HKEY_CLASSES_ROOT,pchar('CLSID\' +
    GuidToString(ClassID) + '\InProcServer32'),
    0,KEY_READ,reg) = ERROR_SUCCESS) then
  try
    dwType := REG_NONE;
    dwLen  := 0;

    if(RegQueryValueEx(reg,nil,nil,@dwType,nil,@dwLen) = ERROR_SUCCESS) and
      (dwType in [REG_SZ,REG_EXPAND_SZ]) and
      (dwLen > 0) then
    begin
      SetLength(s,dwLen);

      if(RegQueryValueEx(reg,nil,nil,@dwType,@s[1],@dwLen) = ERROR_SUCCESS) then
        SetLength(s,dwLen-1)
      else
        s := '';

      Result := (s <> '') and
        (fileexists(ExpandEnvStr(s)));
    end;
  finally
    RegCloseKey(reg);
  end;
end;

function ExtractResToTemp(const Module: HINST; ResourceName,
  ResourceType: pchar; out TempFileName: string): boolean;
var
  ResInfo  : HRSRC;
  ResSize  : dword;
  ResData  : pointer;
  FileOut  : THandle;
  Written  : dword;
begin
  // get Temp folder
  Result   := CreateTempFilename('res',TempFileName);
  if(not Result) then exit;

  // extract resource
  Result   := false;
  ResInfo  := FindResource(Module,ResourceName,ResourceType);
  if(ResInfo <> 0) then
  begin
    ResSize := SizeOfResource(Module,ResInfo);
    ResData := LockResource(LoadResource(Module,ResInfo));

    if(ResSize > 0) and (ResData <> nil) then
    begin
      FileOut := CreateFile(pchar(TempFileName),GENERIC_WRITE,FILE_SHARE_READ,
        nil,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0);
      if(FileOut <> INVALID_HANDLE_VALUE) then
      begin
        Result := WriteFile(FileOut,ResData^,ResSize,Written,nil) and
          (Written = ResSize);

        CloseHandle(FileOut);
      end;
    end;
  end;
end;


// -----------------------------------------------------------------------------

function IsManifestAvailable(const FileName: string): boolean;
const
  RT_MANIFEST = MAKEINTRESOURCE(24);

  function ManifestProc(module: HMODULE; lpszType: PAnsiChar;
    lp: LPARAM): bool; stdcall;
  begin
    Result := not(lpszType = RT_MANIFEST);
  end;

var
  module : HINST;
begin
  Result := false;

  // the file does not exist
  if not fileexists(FileName) then exit;

  // this is not Windows XP or newer
  if not IsWindowsXp then exit;

  // is there a regular .manifest file?
  Result := fileexists(FileName + '.manifest');

  // is there a manifest resource?
  if not Result then
  begin
    module := LoadLibrary(pchar(FileName));
    if module <> 0 then
      Result := not EnumResourceTypes(module, @ManifestProc, 0);
  end;
end;


// -----------------------------------------------------------------------------

//
// Shell helpers
//
const
  shlwapi = 'shlwapi.dll';

function PathAddBackslash; external shlwapi name 'PathAddBackslashA';
function PathAddExtension; external shlwapi name 'PathAddExtensionA';
function PathAppend; external shlwapi name 'PathAppendA';
function PathBuildRoot; external shlwapi name 'PathBuildRootA';
function PathCanonicalize; external shlwapi name 'PathCanonicalizeA';
function PathCombine; external shlwapi name 'PathCombineA';
function PathCompactPath; external shlwapi name 'PathCompactPathA';
function PathCompactPathEx; external shlwapi name 'PathCompactPathExA';
function PathCommonPrefix; external shlwapi name 'PathCommonPrefixA';
function PathFileExists; external shlwapi name 'PathFileExistsA';
function PathFindExtension; external shlwapi name 'PathFindExtensionA';
function PathFindFileName; external shlwapi name 'PathFindFileNameA';
function PathFindNextComponent; external shlwapi name 'PathFindNextComponentA';
function PathFindOnPath; external shlwapi name 'PathFindOnPathA';
function PathGetArgs; external shlwapi name 'PathGetArgsA';
function PathFindSuffixArray; external shlwapi name 'PathFindSuffixArrayA';
function PathIsLFNFileSpec; external shlwapi name 'PathIsLFNFileSpecA';
function PathGetCharType; external shlwapi name 'PathGetCharTypeA';
function PathGetDriveNumber; external shlwapi name 'PathGetDriveNumberA';
function PathIsDirectory; external shlwapi name 'PathIsDirectoryA';
function PathIsDirectoryEmpty; external shlwapi name 'PathIsDirectoryEmptyA';
function PathIsFileSpec; external shlwapi name 'PathIsFileSpecA';
function PathIsPrefix; external shlwapi name 'PathIsPrefixA';
function PathIsRelative; external shlwapi name 'PathIsRelativeA';
function PathIsRoot; external shlwapi name 'PathIsRootA';
function PathIsSameRoot; external shlwapi name 'PathIsSameRootA';
function PathIsUNC; external shlwapi name 'PathIsUNCA';
function PathIsNetworkPath; external shlwapi name 'PathIsNetworkPathA';
function PathIsUNCServer; external shlwapi name 'PathIsUNCServerA';
function PathIsUNCServerShare; external shlwapi name 'PathIsUNCServerShareA';
function PathIsContentType; external shlwapi name 'PathIsContentTypeA';
function PathIsURL; external shlwapi name 'PathIsURLA';
function PathMakePretty; external shlwapi name 'PathMakePrettyA';
function PathMatchSpec; external shlwapi name 'PathMatchSpecA';
function PathParseIconLocation; external shlwapi name 'PathParseIconLocationA';
procedure PathQuoteSpaces; external shlwapi name 'PathQuoteSpacesA';
function PathRelativePathTo; external shlwapi name 'PathRelativePathToA';
procedure PathRemoveArgs; external shlwapi name 'PathRemoveArgsA';
function PathRemoveBackslash; external shlwapi name 'PathRemoveBackslashA';
procedure PathRemoveBlanks; external shlwapi name 'PathRemoveBlanksA';
procedure PathRemoveExtension; external shlwapi name 'PathRemoveExtensionA';
function PathRemoveFileSpec; external shlwapi name 'PathRemoveFileSpecA';
function PathRenameExtension; external shlwapi name 'PathRenameExtensionA';
function PathSearchAndQualify; external shlwapi name 'PathSearchAndQualifyA';
procedure PathSetDlgItemPath; external shlwapi name 'PathSetDlgItemPathA';
function PathSkipRoot; external shlwapi name 'PathSkipRootA';
procedure PathStripPath; external shlwapi name 'PathStripPathA';
function PathStripToRoot; external shlwapi name 'PathStripToRootA';
procedure PathUnquoteSpaces; external shlwapi name 'PathUnquoteSpacesA';
function PathMakeSystemFolder; external shlwapi name 'PathMakeSystemFolderA';
function PathUnmakeSystemFolder; external shlwapi name 'PathUnmakeSystemFolderA';
function PathIsSystemFolder; external shlwapi name 'PathIsSystemFolderA';
procedure PathUndecorate; external shlwapi name 'PathUndecorateA';
function PathUnExpandEnvStrings; external shlwapi name 'PathUnExpandEnvStringsA';

function GetVersionExA; external kernel32 name 'GetVersionExA';
function GetVersionExW; external kernel32 name 'GetVersionExW';
function GetVersionEx; external kernel32 name 'GetVersionExA';

// -----------------------------------------------------------------------------

function GetWindowsInfo(out NTPlatform: boolean;
  out Major, Minor, SPMajor: dword): boolean;
var
  os : TOSVersionInfo;
begin
  NTPlatform := false;
  Major := 0;
  Minor := 0;

  ZeroMemory(@os, sizeof(os));
  os.dwOSVersionInfoSize := sizeof(os);
  Result := GetVersionEx(os);

  if Result then
  begin
    NTPlatform := os.dwPlatformId = VER_PLATFORM_WIN32_NT;
    Major := os.dwMajorVersion;
    Minor := os.dwMinorVersion;
    SPMajor := os.wServicePackMajor;
  end;
end;


var
  NTPlatform : boolean;
  Major,
  Minor,
  SPMajor    : dword;

initialization
  if GetWindowsInfo(NTPlatform, Major, Minor, SPMajor) then
  begin
    IsWindows2000  := (NTPlatform) and (Major = 5) and (Minor = 0);
    IsWindowsXP    := (NTPlatform) and (Major = 5) and (Minor >= 1);
    IsWindowsXPSp2 := (IsWindowsXP) and (SPMajor >= 2);
    IsWindowsVista := (NTPlatform) and (Major >= 6);
  end;
end.