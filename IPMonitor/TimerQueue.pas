unit TimerQueue;

interface

type
  THandle = Cardinal;
  DWORD = Cardinal;
  ULONG = Cardinal;
  BOOL = Boolean;

type
  WAITORTIMERCALLBACKFUNC = procedure(P: Pointer; B: ByteBool); stdcall;
  WAITORTIMERCALLBACK = WAITORTIMERCALLBACKFUNC;

function CreateTimerQueueTimer(var phNewTimer: THandle; TimerQueue: THandle;
  Callback: WAITORTIMERCALLBACK; Parameter: Pointer; DueTime, Period: DWORD;
  Flags: ULONG): BOOL; stdcall;

function DeleteTimerQueueTimer(TimerQueue, Timer, CompletionEvent: THandle):
  BOOL; stdcall;

implementation

function CreateTimerQueueTimer; external 'kernel32.dll' name
  'CreateTimerQueueTimer';

function DeleteTimerQueueTimer; external 'kernel32.dll' name
  'DeleteTimerQueueTimer';

end.

 