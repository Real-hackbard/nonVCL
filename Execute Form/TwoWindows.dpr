program TwoWindows;

uses
  Windows,
  Messages;

const
  ClassName1 = 'Wnd1Class';
  ClassName2 = 'Wnd2Class';
  Window1Name = 'Window 1';
  Window2Name = 'Window 2';
  WindowWidth1 = 500;
  WindowHeight1 = 400;
  WindowWidth2 = 300;
  WindowHeight2 = 200;

  IDC_BUTTON1 = 1;

var
  hWnd2: DWORD;

  hwndButton1: DWORD;

{Window function for windows 1}
function Wnd1Proc(hWnd1: HWND; uMsg: UINT; wParam: wParam; lParam: LParam):
  lresult; stdcall;
var
  x, y : integer;
begin
  Result := 0;
  case uMsg of
    WM_CREATE:
      begin
        {Center window}
        x := GetSystemMetrics(SM_CXSCREEN);
        y := GetSystemMetrics(SM_CYSCREEN);
        MoveWindow(hWnd1, (x div 2) - (WindowWidth1 div 2),
          (y div 2) - (WindowHeight1 div 2),
          WindowWidth1, WindowHeight1, true);

        hwndButton1 := CreateWindowEx(0, 'BUTTON', 'Click',
          WS_CHILD or WS_VISIBLE, 200, 160,
          100, 25, hWnd1, IDC_BUTTON1, hInstance, nil);
      end;
    WM_COMMAND:
      begin
        if hiword(wParam) = BN_CLICKED then
          case loword(wParam) of
            IDC_BUTTON1:
              {Create and display window 2}
              hwnd2 := CreateWindowEx(0, ClassName2, Window2Name,
                WS_OVERLAPPEDWINDOW or WS_VISIBLE, 40, 10,
                300, 200, hWnd1, 0, hInstance, nil);
          end;
      end;
    WM_DESTROY:
      begin
        PostQuitMessage(0);
      end;
  else
    Result := DefWindowProc(hWnd1, uMsg, wParam, lParam);
  end;
end;

{Window function for windows 2}
function Wnd2Proc(hWnd2: HWND; iMsg: UINT; wParam: wParam; lParam: LParam):
  lresult; stdcall;
var
  x, y : integer;
begin
  Result := 0;
  case iMsg of
    WM_CREATE:
      begin
        {Center window}
        x := GetSystemMetrics(SM_CXSCREEN);
        y := GetSystemMetrics(SM_CYSCREEN);
        MoveWindow(hWnd2, (x div 2) - (WindowWidth2 div 2),
          (y div 2) - (WindowHeight2 div 2),
          WindowWidth2, WindowHeight2, true);
      end;
    else
      Result := DefWindowProc(hWnd2, iMsg, wParam, lParam);
  end;
end;

{Window structure for both windows}
var
  wc: TWndClassEx = (
    cbSize          : SizeOf(TWndClassEx);
    Style           : CS_HREDRAW or CS_VREDRAW;
    lpfnWndProc     : @Wnd1Proc;    //Window function for windows 1
    cbClsExtra      : 0;
    cbWndExtra      : 0;
    hbrBackground   : COLOR_APPWORKSPACE;
    lpszMenuName    : nil;
    lpszClassName   : ClassName1;   //Klassenname für Fenster 1
    hIconSm         : 0;
  );
  msg: TMsg;

begin
  {Fill structure with information for window 1}
  wc.hInstance  := hInstance;
  wc.hIcon      := LoadIcon(hInstance,MAKEINTRESOURCE(100));
  wc.hCursor    := LoadCursor(0, IDC_ARROW);

  {Register window 1}
  RegisterClassEx(wc);

  {Create window 1 and assign hWnd1}
  CreateWindowEx(0, ClassName1, Window1Name, WS_VISIBLE or
    WS_OVERLAPPEDWINDOW,
    CW_USEDEFAULT, CW_USEDEFAULT, WindowWidth1, WindowHeight1, 0, 0, hInstance,
    nil);

  {Fill structure with information for window 2}
  wc.hInstance  := hInstance;
  wc.lpfnWndProc := @Wnd2Proc;  //Window function for window 2
  wc.hIcon      := LoadIcon(0, IDI_INFORMATION);
  wc.hCursor    := LoadCursor(0, IDC_ARROW);
  wc.lpszClassName := ClassName2;   //Class name for window 2

  {Register window 2}
  RegisterClassEx(wc);

  while GetMessage(msg,0,0,0) do
  begin
    TranslateMessage(msg);
    DispatchMessage(msg);
  end;
  ExitCode := msg.wParam;
end.
