const
  SYSTEMPROCESSINFORMATION = 5;
  STATUS_INFO_LENGTH_MISMATCH = Integer($C0000004);

type
  UNICODE_STRING = record
    Length: Word;
    MaximumLength: Word;
    Buffer: PWideChar;
  end;
  PUNICODE_STRING = ^UNICODE_STRING;
  TUNICODE_STRING = UNICODE_STRING;

  _SYSTEM_PROCESS_INFORMATION = record
    NextEntryOffset: ULONG;
    NumberOfThreads: ULONG;
    SpareLi1, SpareLi2, SpareLi3: TLargeInteger;
    CreateTime, UserTime, KernelTime: LARGE_INTEGER;
    ImageName: UNICODE_STRING;
    BasePriority: ULONG;
    UniqueProcessId: THandle;
    InheritedFromUniqueProcessId: THandle;
    HandleCount: ULONG;
    SessionId: ULONG;
    SpareUl3: ULONG;
    PeekVirtualSize: ULONG;
    VirtualSize: ULONG;
    PageFaultCount: ULONG;
    PeakWorkingSetSize: ULONG;
    WorkingSetSize: ULONG;
    QuotaPeakPagedPoolUsage: ULONG;
    QuotaPagedPoolUsage: ULONG;
    QuotaPeakNonPagedPoolUsage: ULONG;
    QuotaNonPagedPoolUsage: ULONG;
    PagefileUsage: ULONG;
    PeakPagefileUsage: ULONG;
    PrivatePageCount: ULONG;
  end;
  TSYSTEM_PROCESS_INFORMATION = _SYSTEM_PROCESS_INFORMATION;
  PSYSTEM_PROCESS_INFORMATION = ^TSYSTEM_PROCESS_INFORMATION;

function NtQuerySystemInformation(SystemInformationClass: Cardinal; SystemInformation: Pointer; Length: ULONG;
  ResultLength: PULONG): Integer; stdcall; external 'ntdll.dll';
function RtlNtStatusToDosError(StatusCode: Integer): DWORD; stdcall; external 'ntdll.dll';
