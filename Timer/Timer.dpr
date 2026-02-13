program Timer;

{$R resource.res}

uses
  Windows,
  Messages;

const
  ClassName = 'WndClass';
  AppName = 'Timer-Demo';
  WindowWidth = 200;
  WindowHeight = 140;

const
  IDC_LABEL = 1;
  IDC_TIMER = 2;

var
  hwndLabel: DWORD;
  hTimer: DWORD;

  i: Integer = 11;

{Window function}
function WndProc(hWnd: HWND; uMsg: UINT; wParam: wParam; lParam: LParam):
  lresult; stdcall;
var
  // Window position variables
  x, y : integer;
  buffer: array[0..255] of Char;
begin
  Result := 0;
  case uMsg of
    WM_CREATE:
      begin
        {Center window}
        x := GetSystemMetrics(SM_CXSCREEN);   // Screen height & width
        y := GetSystemMetrics(SM_CYSCREEN);
        {Move window to new position}
        MoveWindow(hWnd, (x div 2) - (WindowWidth div 2),
          (y div 2) - (WindowHeight div 2),
          WindowWidth, WindowHeight, true);

        {Create label}
        hwndLabel := CreateWindowEx(WS_EX_CLIENTEDGE, 'STATIC', 'Countdown',
          WS_VISIBLE or WS_CHILD or SS_CENTER, 30, 40, 130, 20, hWnd, IDC_LABEL,
          hInstance, nil);

        {Zeitgeber erstellen}
        hTimer := SetTimer(hWnd, IDC_TIMER, 1000, nil);
      end;
    WM_DESTROY: PostQuitMessage(0);
    WM_TIMER:
      begin
        Dec(i);
        wvsprintf(buffer, 'Countdown %d', PChar(@i));
        SetWindowText(hwndLabel, buffer);
        if i = 0 then
        begin
          KillTimer(hWnd, IDC_TIMER);
          SetWindowText(hwndLabel, 'BOOOOM!!!');
        end;
      end;
  else
    Result := DefWindowProc(hWnd, uMsg, wParam, lParam);
  end;
end;

var
  {Window class structure}
  wc: TWndClassEx = (
    cbSize          : SizeOf(TWndClassEx);
    Style           : CS_HREDRAW or CS_VREDRAW;
    lpfnWndProc     : @WndProc;
    cbClsExtra      : 0;
    cbWndExtra      : 0;
    hbrBackground   : COLOR_APPWORKSPACE;
    lpszMenuName    : nil;
    lpszClassName   : ClassName;
    hIconSm         : 0;
  );
  msg: TMsg;

begin
  wc.hInstance  := hInstance;
  wc.hIcon      := LoadIcon(hInstance, MAKEINTRESOURCE(100));
  wc.hCursor    := LoadCursor(0, IDC_ARROW);

  {Register windows}
  RegisterClassEx(wc);

  {Show window}
  CreateWindowEx(0, ClassName, AppName, WS_CAPTION or WS_VISIBLE or WS_SYSMENU,
    CW_USEDEFAULT, CW_USEDEFAULT, WindowWidth, WindowHeight, 0, 0, hInstance,
    nil);

  {Start message loop}
  while GetMessage(msg,0,0,0) do
  begin
    TranslateMessage(msg);
    DispatchMessage(msg);
  end;
  ExitCode := msg.wParam;
end.