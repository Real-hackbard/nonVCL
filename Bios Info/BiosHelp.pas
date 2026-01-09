unit BiosHelp {platform};

{$MINENUMSIZE 4}
{$WEAKPACKAGEUNIT}

interface

const
  RomBiosDumpBase    = Cardinal($000C0000);
  RomBiosDumpBasePtr = Pointer(RomBiosDumpBase);
  RomBiosDumpEnd     = Cardinal($000FFFFF);
  RomBiosDumpEndPtr  = Pointer(RomBiosDumpEnd);
  RomBiosDumpSize    = Cardinal(RomBiosDumpEnd - RomBiosDumpBase + 1);

type
  PRomBiosDump = ^TRomBiosDump;
  TRomBiosDump = record
    ByteArray: array [0..RomBiosDumpSize - 1] of Byte;
  end;

type
  TRomDumpMethod = (
    rdmAutomatic,  // Autodetect OS type and use proper method
    rdmGeneric,    // Dump with external 16bit program (Win32)
    rdmMemory,     // Dump from process' address space (Win9x)
    rdmPhysical,   // Dump from physical memory object (WinNT)
    rdmDevMem,     // Dump from memory device /dev/mem (Linux)
    rdmFirmware    // Dump with GetSystemFirmwareTable (XPx64)
  );

function DumpRomBios(out Dump: TRomBiosDump;
  Method: TRomDumpMethod = rdmAutomatic; Timeout: Longword = 5000): Boolean;
function DumpRomBiosEx(RomBase: Pointer; RomSize: Cardinal; out Dump;
  Method: TRomDumpMethod = rdmAutomatic; Timeout: Longword = 5000): Boolean;

procedure ReadRomDumpBuffer(const Dump: TRomBiosDump; Addr: Pointer;
  out Buffer; Size: Cardinal);
procedure ReadRomDumpBufferEx(const Dump; Base, Addr: Pointer;
  out Buffer; Size: Cardinal);

function GetRomDumpAddr(const Dump: TRomBiosDump; Addr: Pointer): Pointer;
function GetRomDumpAddrEx(const Dump; Base, Addr: Pointer): Pointer;

implementation

uses
{$IFDEF WIN32}
  Windows;
{$ELSE}
  {$IFDEF LINUX}
  Libc;
  {$ELSE !LINUX}
    {$MESSAGE ERROR 'BiosHelp: Unsupported Target Platform'}
  {$ENDIF LINUX}
{$ENDIF WIN32}

{$IFDEF LINUX}

const
  ERROR_SUCCESS = 0;
  ERROR_INVALID_PARAMETER = EINVAL;
  ERROR_CALL_NOT_IMPLEMENTED = ENOSYS;

function SetLastError(Error: Longword): Longword;
var
  errno: PInteger;
begin
  errno := __errno_location();
  Result := Longword(errno^);
  Longword(errno^) := Error;
end;

{$ENDIF LINUX}

////////////////////////////////////////////////////////////////////////////////
//
//  DumpRomBios16 (rdmGeneric)
//
//    Creates an 16-bit EXE program in TEMP and runs it redirected to an file.
//
//    WARNING: One day 16-bit code will not run on future Windows.
//    WARNING: You are dumping the BIOS inside the MS-DOS 'emulator'.
//
//    Well, year 2005 -- Windows XP/2003 x64 Edition doesn't support 16-bit...
//

{$IFDEF WIN32}

function _RomDumpCode(RomBase: Pointer; RomSize: Cardinal;
  out Code: Pointer; out Size: Cardinal): Boolean;
const
  BlockSize = $1000;
type                                  { ; RomDump (dumps memory to STDOUT)     }
  PRomDumpCode = ^TRomDumpCode;       { ; Copyright (c) 2005 Nico Bendlin      }
  TRomDumpCode = packed record        { ; (BlockSize MUST be multiple of 10h)  }
    head: TImageDosHeader;            {                                        }
    note: array [0..$4F] of AnsiChar; { @@note: db      'RomDump', ...         }
    init: packed record               { @@init:                                }
      x00050: array [0..2] of Byte;   {         mov     ax, 4400h              }
      x00053: array [0..2] of Byte;   {         mov     bx, 0001h              }
      x00056: array [0..1] of Byte;   {         int     21h                    }
      x00058: array [0..1] of Byte;   {         jc      @@code                 }
      x0005A: array [0..3] of Byte;   {         and     dx, 0082h              }
      x0005E: array [0..3] of Byte;   {         cmp     dx, 0082h              }
      x00062: array [0..1] of Byte;   {         jne     @@code                 }
      x00064: Byte;                   {         push    cs                     }
      x00065: Byte;                   {         push    ds                     }
      x00066: array [0..2] of Byte;   {         mov     dx, offset @@note      }
      x00069: array [0..1] of Byte;   {         mov     ah, 09h                }
      x0006B: array [0..1] of Byte;   {         int     21h                    }
      x0006D: array [0..2] of Byte;   {         mov     ax, 4C01h              }
      x00070: array [0..1] of Byte;   {         int     21h                    }
    end;                              {                                        }
    code: packed record               { @@code:                                }
      x00072: Byte; BlockCount: Word; {         mov     cx, <BlockCount>       }
      x00075: Byte; DatSegment: Word; {         mov     dx, <DatSegment>       }
      x00078: array [0..1] of Byte;   {         jcxz    @@last                 }
    end;                              {                                        }
    loop: packed record               { @@loop:                                }
      x0007A: Byte;                   {         push    cx                     }
      x0007B: Byte;                   {         push    dx                     }
      x0007C: array [0..1] of Byte;   {         mov     ds, dx                 }
      x0007E: Byte; DatOffset: Word;  {         mov     dx, <DatOffset>        }
      x00081: array [0..2] of Byte;   {         mov     cx, <BlockSize>        }
      x00084: array [0..2] of Byte;   {         mov     bx, 0001h              }
      x00087: array [0..2] of Byte;   {         mov     ax, 4000h              }
      x0008A: array [0..1] of Byte;   {         int     21h                    }
      x0008C: Byte;                   {         pop     dx                     }
      x0008D: Byte;                   {         pop     cx                     }
      x0008E: array [0..1] of Byte;   {         jc      @@exit                 }
      x00090: array [0..3] of Byte;   {         add     dx, <BlockSize / 10h>  }
      x00094: array [0..1] of Byte;   {         loop    @@loop                 }
    end;                              {                                        }
    last: packed record               { @@last:                                }
      x00096: array [0..1] of Byte;   {         mov     ds, dx                 }
      x00098: Byte; DatOffset: Word;  {         mov     dx, <DatOffset>        }
      x0009B: Byte; LenghtMod: Word;  {         mov     cx, <LenghtMod>        }
      x0009E: array [0..2] of Byte;   {         mov     bx, 0001h              }
      x000A1: array [0..2] of Byte;   {         mov     ax, 4000h              }
      x000A4: array [0..1] of Byte;   {         jcxz    @@exit                 }
      x000A6: array [0..1] of Byte;   {         int     21h                    }
      x000A8: array [0..1] of Byte;   {         jc      @@exit                 }
      x000AA: array [0..1] of Byte;   {         mov     al, 00h                }
    end;                              {                                        }
    exit: packed record               { @@exit:                                }
      x000AC: array [0..1] of Byte;   {         mov     ah, 4Ch                }
      x000AE: array [0..1] of Byte;   {         int     21h                    }
    end;                              {                                        }
  end;                                {                                        }
const
  RomDumpCodeSize = SizeOf(TRomDumpCode) - SizeOf(TImageDosHeader);
  RomDumpCode: TRomDumpCode = (
    head: (
      e_magic   : IMAGE_DOS_SIGNATURE;
      e_cblp    : Word(RomDumpCodeSize) and $1FF;
      e_cp      : Word((RomDumpCodeSize - 1) shr 9) + 1;
      e_crlc    : $0000;
      e_cparhdr : SizeOf(TImageDosHeader) shr 4;
      e_minalloc: $0000;
      e_maxalloc: $FFFF;
      e_ss      : $0000;
      e_sp      : $1000;
      e_csum    : $0000;
      e_ip      : SizeOf(RomDumpCode.note);
      e_cs      : $0000;
      e_lfarlc  : SizeOf(TImageDosHeader);
      e_ovno    : $0000;
      e_res     : ($0000, $0000, $0000, $0000);
      e_oemid   : $0000;
      e_oeminfo : $0000;
      e_res2    : (
        $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000);
      _lfanew   : $00000000
    );
    note: #13#10'RomDump 3.0'#13#10 +
      'Copyright (c) 2005 Nico Bendlin'#13#10#13#10 +
      'Usage: RomDump > filename'#13#10#13#10'$';
    init: (
      x00050: ($B8, $00, $44);
      x00053: ($BB, $01, $00);
      x00056: ($CD, $21);
      x00058: ($72, $18);
      x0005A: ($81, $E2, $82, $00);
      x0005E: ($81, $FA, $82, $00);
      x00062: ($75, $0E);
      x00064: $0E;
      x00065: $1F;
      x00066: ($BA, $00, $00);
      x00069: ($B4, $09);
      x0006B: ($CD, $21);
      x0006D: ($B8, $01, $4C);
      x00070: ($CD, $21);
    );
    code: (
      x00072: $B9; BlockCount: Word(RomBiosDumpSize div BlockSize);
      x00075: $BA; DatSegment: Word(RomBiosDumpBase shr 4);
      x00078: ($E3, $1C)
    );
    loop: (
      x0007A: $51;
      x0007B: $52;
      x0007C: ($8E, $DA);
      x0007E: $BA; DatOffset: Word(RomBiosDumpBase and $000F);
      x00081: ($B9, Lo(BlockSize), Hi(BlockSize));
      x00084: ($BB, $01, $00);
      x00087: ($B8, $00, $40);
      x0008A: ($CD, $21);
      x0008C: $5A;
      x0008D: $59;
      x0008E: ($72, $1C);
      x00090: ($81, $C2, Lo(BlockSize shr 4), Hi(BlockSize shr 4));
      x00094: ($E2, $E4)
    );
    last: (
      x00096: ($8E, $DA);
      x00098: $BA; DatOffset: Word(RomBiosDumpBase and $000F);
      x0009B: $B9; LenghtMod: Word(RomBiosDumpSize mod BlockSize);
      x0009E: ($BB, $01, $00);
      x000A1: ($B8, $00, $40);
      x000A4: ($E3, $06);
      x000A6: ($CD, $21);
      x000A8: ($72, $02);
      x000AA: ($B0, $00)
    );
    exit: (
      x000AC: ($B4, $4C);
      x000AE: ($CD, $21)
    )
  );
begin
  Result := False;
  if (RomSize > 0) and (RomSize <= $100000) and
    (Cardinal(RomBase) < $100000) and
    (Cardinal(RomBase) + RomSize <= $100000) then
  begin
    Size := SizeOf(TRomDumpCode);
    Code := Pointer(LocalAlloc(LPTR, Size));
    if Code <> nil then
    try
      PRomDumpCode(Code)^ := RomDumpCode;
      with PRomDumpCode(Code)^ do
      begin
        code.BlockCount := Word(RomSize div BlockSize);
        code.DatSegment := Word(Cardinal(RomBase) shr 4);
        loop.DatOffset := Word(Cardinal(RomBase)) and $000F;
        last.DatOffset := loop.DatOffset;
        last.LenghtMod := Word(RomSize mod BlockSize);
      end;
      Result := True;
    except
      LocalFree(HLOCAL(Code));
      Code := nil;
      Size := 0;
    end;
  end;
end;

function _SaveRomDumpCodeToFile(RomBase: Pointer; RomSize: Cardinal;
  const Filename: string): Boolean;
var
  Code: Pointer;
  Size: Cardinal;
  Hand: THandle;
  Num: DWORD;
begin
  Result := False;
  if _RomDumpCode(RomBase, RomSize, Code, Size) then
  try
    Hand := CreateFile(PChar(Filename), GENERIC_WRITE, FILE_SHARE_READ, nil,
      CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
    if Hand <> INVALID_HANDLE_VALUE then
    try
      Result := WriteFile(Hand, Code^, Size, Num, nil) and (Num = Size);
      if not Result then
        DeleteFile(PChar(Filename));
    finally
      CloseHandle(Hand);
    end;
  finally
    LocalFree(HLOCAL(Code));
  end;
end;

function _ExecuteRomDumpCode(const Code, Dump: string; Timeout: DWORD): Boolean;
var
  ComSpec: string;
  StartInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
  ErrorMode: Cardinal;
begin
  Result := False;
  SetLength(ComSpec, MAX_PATH + 1);
  SetLength(ComSpec,
    GetEnvironmentVariable('ComSpec', PChar(@ComSpec[1]), MAX_PATH));
  if Length(ComSpec) <= 0 then
    Exit;
  FillChar(StartInfo, SizeOf(TStartupInfo), 0);
  StartInfo.cb := SizeOf(TStartupInfo);
  StartInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartInfo.wShowWindow := SW_HIDE;
  ErrorMode := SetErrorMode(SEM_FAILCRITICALERRORS or SEM_NOGPFAULTERRORBOX or
    SEM_NOALIGNMENTFAULTEXCEPT or SEM_NOOPENFILEERRORBOX);
  try
    if CreateProcess(nil, PChar(ComSpec + ' /C ' + Code + ' > ' + Dump),
      nil, nil, False, HIGH_PRIORITY_CLASS, nil, nil, StartInfo, ProcInfo) then
    try
      Result :=
        (WaitForSingleObject(ProcInfo.hProcess, Timeout) <> WAIT_TIMEOUT);
      if not Result then
        TerminateProcess(ProcInfo.hProcess, STATUS_TIMEOUT);
    finally
      CloseHandle(ProcInfo.hThread);
      CloseHandle(ProcInfo.hProcess);
    end;
  finally
    SetErrorMode(ErrorMode);
  end;
end;

{$ENDIF WIN32}

function DumpRomBios16(RomBase: Pointer; RomSize: Cardinal; out Dump;
  Timeout: Longword): Boolean;
{$IFDEF WIN32}
var
  Tmp: array [0..MAX_PATH] of Char;
  Dmp: array [0..MAX_PATH] of Char;
  Exe: array [0..MAX_PATH] of Char;
  Hnd: THandle;
  Num: DWORD;
{$ENDIF WIN32}
begin
  Result := False;
{$IFDEF WIN32}
  if GetTempPath(MAX_PATH, Tmp) > 0 then
    GetShortPathName(Tmp, Tmp, MAX_PATH)
  else
    lstrcpy(Tmp, '.');
  if GetTempFileName(Tmp, 'rom', 0, Dmp) > 0 then
  try
    lstrcpy(Exe, Dmp);
    lstrcat(Exe, '.exe');  // Win9x requires .EXE extention
    if _SaveRomDumpCodeToFile(RomBase, RomSize, Exe) then
    try
      if _ExecuteRomDumpCode(Exe, Dmp, Timeout) then
      begin
        Hnd := CreateFile(Dmp, GENERIC_READ, FILE_SHARE_READ or
          FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
        if Hnd <> INVALID_HANDLE_VALUE then
        try
          Result := ReadFile(Hnd, Dump, RomSize, Num, nil) and (Num = RomSize);
        finally
          CloseHandle(Hnd);
        end;
      end;
    finally
      DeleteFile(Exe);
    end;
  finally
    DeleteFile(Dmp);
  end;
{$ELSE !WIN32}
  SetLastError(ERROR_CALL_NOT_IMPLEMENTED);
{$ENDIF WIN32}
end;

////////////////////////////////////////////////////////////////////////////////
//
//  DumpRomBios9x (rdmMemory)
//
//    Win9x maps the BIOS into every process - therefore it's directly accessed.
//

function DumpRomBios9x(RomBase: Pointer; RomSize: Cardinal; out Dump): Boolean;
begin
  Result := False;
  try
    Move(RomBase^, Dump, RomSize);
    Result := True;
  except
    // ignore exeptions
  end
end;

////////////////////////////////////////////////////////////////////////////////
//
//  DumpRomBiosNt (rdmPhysical)
//
//    On WinNT the BIOS is accessable through section '\Device\PhysicalMemory'.
//    This object can only be opened by members of local 'Adminstrators' group.
//    ZwOpenSection and RtlNtStatusToDosError are documented in newer MSDN/DDK.
//
//    Well, year 2005 -- in Windows 2003 Server SP1 and Windows XP x64 Edition
//    the access to the section object is ALWAYS denied for user mode code ...
//

{$IFDEF WIN32}

type
  NTSTATUS = Integer;

  PUnicodeString = ^TUnicodeString;
  TUnicodeString = packed record
    Length       : Word;
    MaximumLength: Word;
    Buffer       : PWideChar;
  end;

  PObjectAttributes = ^TObjectAttributes;
  TObjectAttributes = record
    Length                  : ULONG;
    RootDirectory           : THandle;
    ObjectName              : PUnicodeString;
    Attributes              : ULONG;
    SecurityDescriptor      : PSecurityDescriptor;
    SecurityQualityOfService: PSecurityQualityOfService;
  end;

  TFNZwOpenSection = function(out Section: THandle; Access: ACCESS_MASK;
    Attributes: PObjectAttributes): NTSTATUS; stdcall;
  TFNRtlNtStatusToDosError = function(Status: NTSTATUS): DWORD; stdcall;

const
  PhysMemDevName = '\Device\PhysicalMemory';
  PhysMemName: TUnicodeString = (
    Length       : Length(PhysMemDevName) * SizeOf(WideChar);
    MaximumLength: Length(PhysMemDevName) * SizeOf(WideChar) + SizeOf(WideChar);
    Buffer       : PhysMemDevName;
  );
  PhysMemMask: ACCESS_MASK = SECTION_MAP_READ;
  PhysMemAttr: TObjectAttributes = (
    Length                  : SizeOf(TObjectAttributes);
    RootDirectory           : 0;
    ObjectName              : @PhysMemName;
    Attributes              : $00000040;  // OBJ_CASE_INSENSITIVE
    SecurityDescriptor      : nil;
    SecurityQualityOfService: nil;
  );

var
  ZwOpenSection: TFNZwOpenSection = nil;
  RtlNtStatusToDosError: TFNRtlNtStatusToDosError = nil;

{$ENDIF WIN32}

function DumpRomBiosNt(RomBase: Pointer; RomSize: Cardinal; out Dump): Boolean;
{$IFDEF WIN32}
var
  HMod: HMODULE;
  Stat: NTSTATUS;
  Sect: THandle;
  View: Pointer;
{$ENDIF WIN32}
begin
  Result := False;
{$IFDEF WIN32}
  HMod := GetModuleHandle('ntdll.dll');
  if HMod = 0 then
    SetLastError(ERROR_CALL_NOT_IMPLEMENTED)
  else
  begin
    if not Assigned(ZwOpenSection) then
      ZwOpenSection := GetProcAddress(HMod, 'ZwOpenSection');
    if not Assigned(RtlNtStatusToDosError) then
      RtlNtStatusToDosError := GetProcAddress(HMod, 'RtlNtStatusToDosError');
    if not Assigned(ZwOpenSection) or not Assigned(RtlNtStatusToDosError) then
      SetLastError(ERROR_CALL_NOT_IMPLEMENTED)
    else
    begin
      Stat := ZwOpenSection(Sect, PhysMemMask, @PhysMemAttr);
      if Stat >= 0 then
      try
        View := MapViewOfFile(Sect, PhysMemMask, 0, Cardinal(RomBase), RomSize);
        if View <> nil then
        try
          Move(View^, Dump, RomSize);
          Result := True;
        finally
          UnmapViewOfFile(View);
        end;
      finally
        CloseHandle(Sect);
      end
      else
        SetLastError(RtlNtStatusToDosError(Stat));
    end;
  end;
{$ELSE !WIN32}
  SetLastError(ERROR_CALL_NOT_IMPLEMENTED);
{$ENDIF WIN32}
end;

////////////////////////////////////////////////////////////////////////////////
//
//  DumpRomBiosMM (rdmDevMem)
//
//    The device /dev/mem is available on most Linux boxes. However, the device
//    would (and should) be only accessable by the superuser (root) and members
//    of the kmem group. So you have to use tools like fakeroot, setuid, or su.
//

function DumpRomBiosMM(RomBase: Pointer; RomSize: Cardinal; out Dump): Boolean;
{$IFDEF LINUX}
var
  Mem: Integer;
  Map: Pointer;
{$ENDIF LINUX}
begin
  Result := False;
{$IFDEF LINUX}
  Mem := open('/dev/mem', O_RDONLY, 0);
  if Mem > 0 then
  try
    Map := mmap(nil, RomSize, PROT_READ, MAP_SHARED, Mem, Integer(RomBase));
    if Map <> MAP_FAILED then
    try
      Move(Map^, Dump, RomSize);
      Result := True;
    finally
      munmap(Map, RomSize);
    end;
  finally
    __close(Mem);
  end;
{$ELSE !LINUX}
  SetLastError(ERROR_CALL_NOT_IMPLEMENTED);
{$ENDIF LINUX}
end;

////////////////////////////////////////////////////////////////////////////////
//
//  DumpRomBiosFw (rdmFirmware)
//
//    Since Windows 2003 Server SP1 and Windows XP x64 Edition always deny the
//    access to the section object '\Device\PhysicalMemory' for user mode code
//    MS introduced new Win32 APIs to get the raw ACPI/Firmware/SMBIOS tables.
//    For now we are only using the 'FIRM' provider - which currently supports
//    to dump the ROM-BIOS memory C000:0000-D000:FFFF and E000:0000-F000:FFFF.
//

{$IFDEF WIN32}

type
  TFNEnumSystemFirmwareTables = function(FirmwareTableProviderSignature: DWORD;
    out pFirmwareTableEnumBuffer; BufferSize: DWORD): UINT; stdcall;
  TFNGetSystemFirmwareTable = function(FirmwareTableProviderSignature: DWORD;
    FirmwareTableID: DWORD; out pFirmwareTableBuffer; BufferSize: DWORD): UINT;
    stdcall;
var
  EnumSystemFirmwareTables: TFNEnumSystemFirmwareTables = nil;
  GetSystemFirmwareTable: TFNGetSystemFirmwareTable = nil;

{$ENDIF WIN32}

function DumpRomBiosFw(RomBase: Pointer; RomSize: Cardinal; out Dump): Boolean;
{$IFDEF WIN32}
type
  PByteArray = ^TByteArray;
  TByteArray = array[0..High(Integer) div SizeOf(Byte) - 1] of Byte;
  PDWordArray = ^TDWordArray;
  TDWordArray = array [0..High(Integer) div SizeOf(DWORD) - 1] of DWORD;
const
  FwTP = $4649524D;  // 'FIRM' The raw firmware table provider.
var
  HMod: HMODULE;
  Size: UINT;
  List: PDWordArray;
  Loop: Integer;
  BLen: UINT;
  Buff: PByteArray;
  Base: Boolean;
  Over: Boolean;
  BOff: UINT;
  DOff: UINT;
{$ENDIF WIN32}
begin
  Result := False;
{$IFDEF WIN32}
  HMod := GetModuleHandle(kernel32);
  if HMod = 0 then
    SetLastError(ERROR_CALL_NOT_IMPLEMENTED)
  else
  begin
    if not Assigned(EnumSystemFirmwareTables) then
      EnumSystemFirmwareTables :=
        GetProcAddress(HMod, 'EnumSystemFirmwareTables');
    if not Assigned(GetSystemFirmwareTable) then
      GetSystemFirmwareTable := GetProcAddress(HMod, 'GetSystemFirmwareTable');
    if not Assigned(EnumSystemFirmwareTables) or
      not Assigned(GetSystemFirmwareTable) then
      SetLastError(ERROR_CALL_NOT_IMPLEMENTED)
    else
    begin
      Size := EnumSystemFirmwareTables(FwTP, nil^, 0) + 2 * SizeOf(DWORD);
      List := PDWordArray(LocalAlloc(LPTR, Size));
      if List <> nil then
      try
        Base := False;
        Over := False;
        FillChar(Dump, RomSize, 0);
        Size := EnumSystemFirmwareTables(FwTP, List^, Size);
        for Loop := 0 to Integer(Size div SizeOf(DWORD)) - 1 do
          if List[Loop] < Cardinal(RomBase) + RomSize then
          begin
            BLen := GetSystemFirmwareTable(FwTP, List[Loop], nil^, 0) + $20000;
            Buff := PByteArray(LocalAlloc(LPTR, BLen));
            if Buff <> nil then
            try
              BLen := GetSystemFirmwareTable(FwTP, List[Loop], Buff^, BLen);
              if (BLen > 0) and (List[Loop] + BLen > Cardinal(RomBase)) then
              begin
                if List[Loop] <= Cardinal(RomBase) then
                begin
                  Base := True;
                  BOff := Cardinal(RomBase) - List[Loop];
                  DOff := 0;
                end
                else
                begin
                  BOff := 0;
                  DOff := List[Loop] - Cardinal(RomBase);
                end;
                if DOff + BLen >= RomSize then
                begin
                  Over := True;
                  BLen := RomSize - DOff;
                end;
                Move(Buff[BOff], TByteArray(Dump)[DOff], BLen);
              end;
            finally
              LocalFree(HLOCAL(Buff));
            end;
          end;
        //FIXME: assumes success if start and end of the dump are filled
        Result := Base and Over;
      finally
        LocalFree(HLOCAL(List));
      end;
    end;
  end;
{$ELSE !WIN32}
  SetLastError(ERROR_CALL_NOT_IMPLEMENTED);
{$ENDIF WIN32}
end;

////////////////////////////////////////////////////////////////////////////////
//
//  DumpRomBios(Ex)
//
//    Public functions to call OS-dependent implementations.
//

function DumpRomBios(out Dump: TRomBiosDump;
  Method: TRomDumpMethod = rdmAutomatic; Timeout: Longword = 5000): Boolean;
begin
  Result := DumpRomBiosEx(RomBiosDumpBasePtr, RomBiosDumpSize, Dump, Method,
    Timeout);
end;

function DumpRomBiosEx(RomBase: Pointer; RomSize: Cardinal; out Dump;
  Method: TRomDumpMethod = rdmAutomatic; Timeout: Longword = 5000): Boolean;
begin
  Result := False;
  SetLastError(ERROR_SUCCESS);
  case Method of
    rdmAutomatic:
{$IFDEF WIN32}
      if (GetVersion() and $80000000) <> 0 then
        Result := DumpRomBios9x(RomBase, RomSize, Dump)
      else
      begin
        //NOTE: Nt/16 changed to Fw/16/Nt (supported/reliable/depreciated)
        Result := DumpRomBiosFw(RomBase, RomSize, Dump);
        if not Result then
          Result := DumpRomBios16(RomBase, RomSize, Dump, Timeout);
        if not Result then
          Result := DumpRomBiosNt(RomBase, RomSize, Dump);
      end;
{$ELSE !WIN32}
  {$IFDEF LINUX}
      Result := DumpRomBiosMM(RomBase, RomSize, Dump);
  {$ENDIF LINUX}
{$ENDIF WIN32}
    rdmGeneric:
      Result := DumpRomBios16(RomBase, RomSize, Dump, Timeout);
    rdmMemory:
      Result := DumpRomBios9x(RomBase, RomSize, Dump);
    rdmPhysical:
      Result := DumpRomBiosNt(RomBase, RomSize, Dump);
    rdmDevMem:
      Result := DumpRomBiosMM(RomBase, RomSize, Dump);
    rdmFirmware:
      Result := DumpRomBiosFw(RomBase, RomSize, Dump);
  else
    SetLastError(ERROR_INVALID_PARAMETER);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//
//  ReadRomDumpBuffer(Ex) / GetRomDumpAddr(Ex)
//
//    Utilities to simplify the access to dumps.
//

procedure ReadRomDumpBuffer(const Dump: TRomBiosDump; Addr: Pointer;
  out Buffer; Size: Cardinal);
begin
  Move(Pointer(Cardinal(@Dump) + Cardinal(Addr) - RomBiosDumpBase)^,
    Buffer, Size);
end;

procedure ReadRomDumpBufferEx(const Dump; Base, Addr: Pointer;
  out Buffer; Size: Cardinal);
begin
  Move(Pointer(Cardinal(@Dump) + Cardinal(Addr) - Cardinal(Base))^,
    Buffer, Size);
end;

function GetRomDumpAddr(const Dump: TRomBiosDump; Addr: Pointer): Pointer;
begin
  Result := Pointer(Cardinal(@Dump) + Cardinal(Addr) - RomBiosDumpBase);
end;

function GetRomDumpAddrEx(const Dump; Base, Addr: Pointer): Pointer;
begin
  Result := Pointer(Cardinal(@Dump) + Cardinal(Addr) - Cardinal(Base));
end;

end.
