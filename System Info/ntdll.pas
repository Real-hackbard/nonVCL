const
  SYS_BASIC_INFO            = 0;
  SYS_PERFORMANCE_INFO      = 2;
  SYS_TIME_INFO             = 3;

type
  SYSTEM_BASIC_INFORMATION = packed record
    dwUnknown1              : DWORD;
    uKeMaximumIncrement     : ULONG;
    uPageSize               : ULONG;
    uMmNumberOfPhysicalPages: ULONG;
    uMmLowestPhysicalPage   : ULONG;
    uMmHighestPhysicalPage  : ULONG;
    uAllocationGranularity  : ULONG;
    pLowestUserAddress      : POINTER;
    pMmHighestUserAddress   : POINTER;
    uKeActiveProcessors     : POINTER;
    bKeNumberProcessors     : BYTE;
    bUnknown2               : BYTE;
    wUnknown3               : WORD;
  end;

  SYSTEM_PERFORMANCE_INFORMATION = packed record
    nIdleTime               : INT64;
    dwSpare                 : array[0..75]of DWORD;
  end;

  SYSTEM_TIME_INFORMATION = packed record
    nKeBootTime             : INT64;
    nKeSystemTime           : INT64;
    nExpTimeZoneBias        : INT64;
    uCurrentTimeZoneId      : ULONG;
    dwReserved              : DWORD;
  end;

  function NTQuerySystemInformation(SystemInformationClass: Longint;
                                    SystemInformation: Pointer;
                                    SystemInformationLength: Longint;
                                    ReturnLength: Longint): Longint; stdcall;
                                    external 'ntdll.dll' name 'NtQuerySystemInformation';
