unit WinInfo;

interface

uses windows;

type TWinInfo = class
  private
    FComputerName : String;
    FUserName     : String;
    FOS           : String;
    FVersion      : String;
    FWinDir       : String;
    FSysDir       : String;
    procedure GetCompName;
    procedure GetUser;
    procedure GetOs;
    procedure GetVersion;
    procedure GetWinDir;
    procedure GetSysDir;
  public
    constructor Create;
    property ComputerName: String read FComputerName;
    property UserName: String read FUserName;
    property OS: String read FOS;
    property Version: String read FVersion;
    property WinDir: String read FWinDir;
    property SysDir: String read FSysDir;
    function IsAdmin: LongBool;
  end;

implementation

{$INCLUDE SysUtils.inc}

constructor TWinInfo.Create;
begin
  GetCompName;
  GetUser;
  GetOs;
  GetVersion;
  GetWinDir;
  GetSysDir;
end;

procedure TWinInfo.GetCompName;
var
  buffer : array[0..MAX_PATH] of Char;
  Size: DWORD;
begin
  Size := sizeof(buffer);
  GetComputerName(buffer, Size);
  SetString(FComputerName, buffer, lstrlen(buffer));
end;

procedure TWinInfo.GetUser;
var
  buffer : array[0..MAX_PATH] of Char;
  Size: DWORD;
begin
  Size := sizeof(buffer);
  GetUserName(buffer, size);
  SetString(FUserName, buffer, lstrlen(buffer));
end;

procedure TWinInfo.GetOs;
var
  osVerInfo    : TOSVersionInfo;
  majorVer, minorVer : Integer;
begin
  FOS := 'unknown';
  { set operating system type flag }
  osVerInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
  if GetVersionEx(osVerInfo) then
  begin
   majorVer := osVerInfo.dwMajorVersion;
   minorVer := osVerInfo.dwMinorVersion;
    case osVerInfo.dwPlatformId of
      VER_PLATFORM_WIN32_NT : { Windows NT/2000 }
        begin
          if majorVer <= 4 then
            FOS := 'Windows NT'
          else if (majorVer = 5) AND (minorVer= 0) then
            FOS := 'Windows 2000'
          else if (majorVer = 5) AND (minorVer = 1) then
            FOS := 'Windows XP'
          else
            FOS := 'unbekannt';
          FOS := FOS + ' (' +osverInfo.szCSDVersion+')';;
        end;
      VER_PLATFORM_WIN32_WINDOWS :  { Windows 9x/ME }
        begin
          if (majorVer = 4) AND (minorVer = 0) then
            FOS := 'Windows 95'
          else if (majorVer = 4) AND (minorVer = 10) then
          begin
            if osVerInfo.szCSDVersion[1] = 'A' then
              FOS := 'Windows 98 SE'
            else
              FOS := 'Windows 98';
          end
          else if (majorVer = 4) AND (minorVer = 90) then
            FOS := 'Windows Millennium'
          else
            FOS := 'unknown';
        end;
    else
      FOS := 'unknown';
    end;
  end
  else
    FOS := 'unknown';
end;

procedure TWinInfo.GetVersion;
var
   osVerInfo    : TOSVersionInfo;
   MajorVer, MinorVer : Integer;
begin
  FVersion := 'unknown';
  { set operating system type flag }
  osVerInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
  if GetVersionEx(osVerInfo) then
  begin
   majorVer := osVerInfo.dwMajorVersion;
   minorVer := osVerInfo.dwMinorVersion;
    case osVerInfo.dwPlatformId of
      VER_PLATFORM_WIN32_NT : { Windows NT/2000 }
        begin
          if majorVer <= 4 then
            FVersion := IntToStr(OsVerInfo.dwMajorVersion)+'.'+IntToStr(OsVerInfo.dwMinorVersion)+
              '.'+IntToStr(OsVerInfo.dwBuildNumber)
          else if (majorVer = 5) AND (minorVer= 0) then
            FVersion := IntToStr(OsVerInfo.dwMajorVersion)+'.'+IntToStr(OsVerInfo.dwMinorVersion)+
              '.'+IntToStr(OsVerInfo.dwBuildNumber)
          else if (majorVer = 5) AND (minorVer = 1) then
            FVersion := IntToStr(OsVerInfo.dwMajorVersion)+'.'+IntToStr(OsVerInfo.dwMinorVersion)+
              '.'+IntToStr(OsVerInfo.dwBuildNumber)
          else
            FVersion := 'unbekannt';
        end;
      VER_PLATFORM_WIN32_WINDOWS :  { Windows 9x/ME }
        begin
          if (majorVer = 4) AND (minorVer = 0) then
            FVersion := IntToStr(OsVerInfo.dwMajorVersion)+'.'+IntToStr(OsVerInfo.dwMinorVersion)+
              '.'+IntToStr(OsVerInfo.dwBuildNumber)
          else if (majorVer = 4) AND (minorVer = 10) then
          begin 
            if osVerInfo.szCSDVersion[1] = 'A' then
              FVersion := IntToStr(OsVerInfo.dwMajorVersion)+'.'+IntToStr(OsVerInfo.dwMinorVersion)+
              '.'+IntToStr(OsVerInfo.dwBuildNumber)
            else
              FVersion := IntToStr(OsVerInfo.dwMajorVersion)+'.'+IntToStr(OsVerInfo.dwMinorVersion)+
              '.'+IntToStr(OsVerInfo.dwBuildNumber)
          end
          else if (majorVer = 4) AND (minorVer = 90) then
            FVersion := IntToStr(OsVerInfo.dwMajorVersion)+'.'+IntToStr(OsVerInfo.dwMinorVersion)+
              '.'+IntToStr(OsVerInfo.dwBuildNumber)
          else
            FVersion := 'unbekannt';
        end;
    else
      FVersion := 'unknown';
    end;
  end
  else
    FVersion := 'unknown';
end;

procedure TWinInfo.GetWinDir;
const
  UNLEN = MAX_PATH;
var
  Size: DWORD;
  buffer : array[0..UNLEN] of Char;
begin
  Size := UNLEN + 1;
  if GetWindowsDirectory(buffer, Size) <> 0 then
    FWinDir := String(buffer)
  else
    FWinDir := '';
end;

procedure TWinInfo.GetSysDir;
const
  UNLEN = MAX_PATH;
var
  Size: DWORD;
  buffer : array[0..UNLEN] of Char;
begin
  Size := UNLEN + 1;
  if GetSystemDirectory(buffer, Size) <> 0 then
    FSysDir := String(buffer)
  else
    FSysDir := '';
end;

{-----------------------------------------------------------------------------
  Procedure : GetAdminSid
  Purpose   : Helper for isAdmin
  Arguments : None
  Result    : PSID
-----------------------------------------------------------------------------}
function GetAdminSid: PSID;
const
  // acquaintance SIDs ... (WinNT.h)
  SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));
  // acquaintance RIDs ... (WinNT.h)
  SECURITY_BUILTIN_DOMAIN_RID: DWORD = $00000020;
  DOMAIN_ALIAS_RID_ADMINS: DWORD = $00000220;
begin
  Result := nil;
  AllocateAndInitializeSid(SECURITY_NT_AUTHORITY, 2,
    SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS,
    0, 0, 0, 0, 0, 0, Result);
end;

{-----------------------------------------------------------------------------
  Procedure : TWinInfo.IsAdmin
  Purpose   : Determins whether user is GOD or not ;o)
  Arguments : None
  Result    : LongBool
-----------------------------------------------------------------------------}
function TWinInfo.IsAdmin: LongBool;
var
  TokenHandle: THandle;
  ReturnLength: DWORD;
  TokenInformation: PTokenGroups;
  AdminSid: PSID;
  Loop: Integer;
begin
  Result := False;
  TokenHandle := 0;
  if OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, TokenHandle) then
  try
    ReturnLength := 0;
    GetTokenInformation(TokenHandle, TokenGroups, nil, 0, ReturnLength);
    TokenInformation := GetMemory(ReturnLength);
    if Assigned(TokenInformation) then
    try
      if GetTokenInformation(TokenHandle, TokenGroups, TokenInformation,
        ReturnLength, ReturnLength) then
      begin
        AdminSid := GetAdminSid;
        for Loop := 0 to TokenInformation^.GroupCount - 1 do
        begin
          if EqualSid(TokenInformation^.Groups[Loop].Sid, AdminSid) then
          begin
            Result := True;
            Break;
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

end.
