program EnumProcesses;

{$APPTYPE CONSOLE}
{$R res\resource.res}

uses
  windows,
  MpuProcessTools in 'units\MpuProcessTools.pas',
  MpuList in 'units\MpuList.pas',
  MpuExceptions in 'units\MpuExceptions.pas',
  CmdLineParser in 'units\CmdLineParser.pas';

const
  APPNAME           = 'EnumProcesses';
  COPYRIGHT         = 'Copyright (c) Michael Puff';
  URI               = 'http://www.michael-puff.de';

resourcestring
  rsContinue        = 'Press Enter to continue...';
  rsProcCount       = 'Number of processes: %d.';
  rsUnknownParam    = 'Unknown commandline switch';
  rsCmdSwitches     = #9 + '/I: ProcessID' + #13#10 +
    #9 + '/J: Parent process ProcessID' + #13#10 +
    #9 + '/F: Filename' + #13#10 +
    #9 + '/P: Path inclusive filename' + #13#10 +
    #9 + '/O: Process owner' + #13#10 +
    #9 + '/C: Base priority class' + #13#10 +
    #9 + '/T: Thread count' + #13#10 +
    #9 + '/M: Module count' + #13#10 +
    #9 + '/T: Createtime of process' + #13#10 +
    #9 + '/U: CPU usage time' + #13#10 +
    #9 + '/K:<PID>: Kill process with the given PID' + #13#10;
  rsKillSuccess     = 'Process successfully killed' + #13#10;

////////////////////////////////////////////////////////////////////////////////
// Procedure : Format
// Comment   : Formats a widestring according to the formatdiscriptors

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

function StrToInt(S: string): Integer;
begin
  Val(S, Result, Result);
end;

function Trim(const S: WideString): WideString;
var
  I, L              : Integer;
begin
  L := Length(S);
  I := 1;
  while (I <= L) and (S[I] <= ' ') do
    Inc(I);
  if I > L then
    Result := ''
  else
  begin
    while S[L] <= ' ' do
      Dec(L);
    Result := Copy(S, I, L - I + 1);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Procedure : GetFileVersion
// Comment   :

function GetFileVersionW(const Filename: WideString): WideString;
type
  PDWORDArr = ^DWORDArr;
  DWORDArr = array[0..0] of DWORD;
var
  VerInfoSize       : DWORD;
  VerInfo           : Pointer;
  VerValueSize      : DWORD;
  VerValue          : PVSFixedFileInfo;
  LangID            : DWORD;
begin
  result := '';
  VerInfoSize := GetFileVersionInfoSizeW(PWideChar(Filename), LangID);
  if VerInfoSize <> 0 then
  begin
    VerInfo := Pointer(GlobalAlloc(GPTR, VerInfoSize * 2));
    if Assigned(VerInfo) then
    try
      if GetFileVersionInfoW(PWideChar(Filename), 0, VerInfoSize, VerInfo) then
      begin
        if VerQueryValueW(VerInfo, '\', Pointer(VerValue), VerValueSize) then
        begin
          with VerValue^ do
          begin
            result := FormatW('%d.%d.%d.%d', [dwFileVersionMS shr 16, dwFileVersionMS and $FFFF,
              dwFileVersionLS shr 16, dwFileVersionLS and $FFFF]);
          end;
        end
        else
          result := '';
      end;
    finally
      GlobalFree(THandle(VerInfo));
    end;
  end;
end;

procedure PrintAbout;
begin
  Writeln(APPNAME + ' - ' + GetFileVersionW(ParamStr(0)));
  Writeln(COPYRIGHT);
  Writeln(URI);
  Writeln;
end;

procedure PrintHelp;
begin
  Writeln('Commandline switches:');
  Writeln(rsCmdSwitches);
end;

function PrintProcID(Process: TProcess): WideString;
begin
  Result := FormatW('%d', [Process.ProcID]);
end;

function PrintParentProcID(Process: TProcess): WideString;
begin
  Result := FormatW('%d', [Process.ParentProcID]);
end;

function PrintFilename(Process: TProcess): WideString;
begin
  Result := Process.ModuleFilename;
end;

function PrintFilepath(Process: TProcess): WideString;
begin
  Result := Process.ModulePath;
end;

function PrintOwner(Process: TProcess): WideString;
begin
  Result := Process.OwnerName;
end;

function PrintCountThreads(Process: TProcess): WideString;
begin
  Result := FormatW('%d', [Process.CountThreads]);
end;

function PrintCountModules(Process: TProcess): WideString;
begin
  Result := FormatW('%d', [Process.CountModules]);
end;

function PrintPriorityClass(Process: TProcess): WideString;
begin
  Result := FormatW('%d', [Process.ProcessPriority]);
end;

function PrintCreateTime(Process: TProcess): WideString;
var
  st                : TSystemTime;
  lft               : TFileTime;
  DateStr           : array[0..254] of WideChar;
  TimeStr           : array[0..254] of WideChar;
begin
  FileTimeToLocalFileTime(Process.CreationTime, lft);
  FileTimeToSystemTime(lft, st);
  if st.wYear <> 1601 then
  begin
    GetDateFormatW(LOCALE_SYSTEM_DEFAULT, DATE_SHORTDATE, @st, nil, DateStr, SizeOf(DateStr));
    GetTimeFormatW(LOCALE_SYSTEM_DEFAULT, TIME_FORCE24HOURFORMAT, @st, nil, TimeStr, SizeOf(TimeStr));
    Result := WideString(TimeStr);
  end;
end;

function PrintCPUTime(Process: TProcess): WideString;
var
  KernelTime64      : LARGE_INTEGER; //TFileTime;
  UserTime64        : LARGE_INTEGER;
  CPUTime64         : LARGE_INTEGER;
  CPUTimeft         : TFileTime;
  st                : TSystemTime;
  TimeStr           : array[0..254] of WideChar;
begin
  KernelTime64.LowPart := Process.KernelTime.dwLowDateTime;
  KernelTime64.HighPart := Process.KernelTime.dwHighDateTime;
  UserTime64.LowPart := Process.UserTime.dwLowDateTime;
  UserTime64.HighPart := Process.UserTime.dwHighDateTime;
  CPUTime64.QuadPart := KernelTime64.QuadPart + UserTime64.QuadPart;
  CPUTimeft.dwLowDateTime := CPUTime64.LowPart;
  CPUTimeft.dwHighDateTime := CPUTime64.HighPart;
  FileTimeToSystemTime(CPUTimeft, st);
  GetTimeFormatW(LOCALE_SYSTEM_DEFAULT, TIME_FORCE24HOURFORMAT, @st, nil, TimeStr, SizeOf(TimeStr));
  Result := WideString(TimeStr);
end;

function PrintOutput(Process: TProcess): WideString;
var
  s                 : WideString;
begin
  if GetCmdLineSwitch('I') then
    s := PrintProcID(Process);
  if GetCmdLineSwitch('J') then
    s := s + #9 + PrintParentProcID(Process);
  if GetCmdLineSwitch('F') then
    s := s + #9 + PrintFilename(Process);
  if GetCmdLineSwitch('P') then
    s := s + #9 + PrintFilepath(Process);
  if GetCmdLineSwitch('O') then
    s := s + #9 + PrintOwner(Process);
  if GetCmdLineSwitch('C') then
    s := s + #9 + PrintPriorityClass(Process);
  if GetCmdLineSwitch('T') then
    s := s + #9 + PrintCountThreads(Process);
  if GetCmdLineSwitch('M') then
    s := s + #9 + PrintCountModules(Process);
  if GetCmdLineSwitch('T') then
    s := s + #9 + PrintCreateTime(Process);
  if GetCmdLineSwitch('U') then
    s := s + #9 + PrintCPUTime(Process);
  Result := trim(s);
end;

var
  ProcList          : TProcessList;
  i                 : Integer;
  s                 : WideString;
  strCmdValue       : string;
  PID               : DWORD;

begin
  if GetCmdLineSwitch('?') then
  begin
    PrintAbout;
    PrintHelp;
    Exit;
  end;

  if GetCmdLineSwitchValue(strCmdValue, 'k') then
  begin
    PID := StrToInt(strCmdValue);
    ProcList := TProcessList.Create(True);
    try
      try
        ProcList.KillProcess(PID, 5000);
        Writeln(rsKillSuccess);
      except
        on E: TMpuProcToolException do
          Writeln(E.Message);
      end;
    finally
      ProcList.Free;
    end;
    exit;
  end;

  ProcList := TProcessList.Create(False);
  try
    try
      ProcList.EnableDebugPrivileges;
      ProcList.EnumProcesses;
      for i := 0 to ProcList.Count - 1 do
      begin
        if ParamCount = 0 then
        begin
          s := PrintProcID(ProcList.Items[i]) + #9 + PrintFilename(ProcList.Items[i]) + #9 +
            PrintOwner(ProcList.Items[i]);
          Writeln(s);
          if (i > 0) and ((i mod 20) = 0) then
          begin
            Write(rsContinue);
            Readln;
          end;
          Continue;
        end;
        Writeln(PrintOutput(ProcList.Items[i]));
        if (i > 0) and ((i mod 20) = 0) then
        begin
          Write(rsContinue);
          Readln;
        end;
      end;
      Writeln('----------------------------------------------------------------------');
      Writeln(FormatW(rsProcCount, [ProcList.Count]));
    except
      on E: TMpuProcToolException do
        Writeln(E.Message);
    end;
  finally
    ProcList.Free;
  end;

  Readln;
end.

