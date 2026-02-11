library KBHook;

uses
  Windows,
  Messages;

type
  PHWND = ^HWND;

const
  WM_KEYBOARD_HOOK = WM_USER + 52012;

var
  hHook: LongWord = 0;
  Key: Word;
  KeyboardLayout: HKL;
  GetShiftKeys: Boolean;
  hWndBuffer: PHWND;
  hMMF: THandle;

function KeyboardProc(nCode: Integer; wParam: LongWord; lParam: LongWord): LongWord; stdcall;
var
  LastKey: Char;
  KeyState: TKeyboardState;
begin
  Result:=CallNextHookEx(hHook,nCode,wParam,lParam);
  if nCode<0 then
    Exit
  else begin
    KeyboardLayout:=GetKeyboardLayout(0);
    GetKeyboardState(KeyState);
    if ToAsciiEx(wParam,MapVirtualKeyEx(wParam,2,KeyboardLayout),KeyState,@LastKey,0,KeyboardLayout)>0 then
      Key:=Ord(LastKey)
    else
      Key:=wParam;
    if (lParam and $80000000)=0 then
      if not (wParam in [16,17,18]) or GetShiftKeys then
        PostMessage(hwndBuffer^,WM_KEYBOARD_HOOK,Key,GetActiveWindow);
  end;
end;

function CreateHook(hWnd: HWND; ShiftKeys: Boolean): Boolean; stdcall;
var
  bHWND: PHWND;
begin
  hMMF:=CreateFileMapping($FFFFFFFF,nil,PAGE_READWRITE or SEC_COMMIT,0,SizeOf(hWnd),'KoshigayaKeyboardHookHandle');
  bHWND:=MapViewOfFile(hMMF,FILE_MAP_WRITE,0,0,SizeOf(HWND));
  bHWND^:=hWnd;
  UnmapViewOfFile(bHWND);
  GetMem(hWndBuffer,SizeOf(HWND));
  hWndBuffer^:=hWnd;  
  GetShiftKeys:=ShiftKeys;
  if hHook=0 then
    hHook:=SetWindowsHookEx(WH_KEYBOARD,@KeyboardProc,hInstance,0);
  Result:=hHook<>0;
end;

function DeleteHook: Boolean; stdcall;
begin
  FreeMem(hWndBuffer);
  CloseHandle(hMMF);
  Result:=UnhookWindowsHookEx(hHook);
  hHook:=0;
end;

exports
  CreateHook,
  DeleteHook;

var
  MMF: THandle;

begin
  MMF:=OpenFileMapping(FILE_MAP_READ,false,'KoshigayaKeyboardHookHandle');
  if MMF<>0 then begin
    hWndBuffer:=MapViewOfFile(MMF,FILE_MAP_READ,0,0,SizeOf(HWND));
    CloseHandle(MMF);
  end;
end.
