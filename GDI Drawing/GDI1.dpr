program GDI1;

uses
  Windows,
  Messages;

const
  ClassName = 'DrawClass';
  AppName = 'Drawing';

  WindowWidth = 500;
  WindowHeight = 400;

function WndProc(hWnd: HWND; uMsg: UINT; wParam: wParam; lParam: LParam):
  lresult; stdcall;
var
  x, y : integer;
  WndDC: HDC;
  ps: TPaintStruct;
  RedBrush, RedBrushOld: HBRUSH;
  GreenHatchBrush, GreenHatchBrushOld: HBRUSH;
  Pen, PenOld: HPEN;
begin
  Result := 0;
  case uMsg of
    WM_CREATE:
    begin
      { Center window }
      x := GetSystemMetrics(SM_CXSCREEN);
      y := GetSystemMetrics(SM_CYSCREEN);
      MoveWindow(hWnd, (x div 2) - (WindowWidth div 2),
        (y div 2) - (WindowHeight div 2),
        WindowWidth, WindowHeight, true);

    end;
    WM_PAINT:
    begin
      WndDC := BeginPaint(hWnd, ps);
      	{ a simple line }
      	MoveToEx(WndDC, 20, 10, nil);
        LineTo(WndDC, 20, 90);

        { a rectangle }
        Rectangle(WndDC, 40, 10, 60, 90);

        { and the whole thing filled }
        RedBrush := CreateSolidBrush(RGB(255, 0, 0));
        RedBrushOld := SelectObject(WndDC, RedBrush);
        Rectangle(WndDC, 80, 10, 100, 90);
        { Restore old brush and delete used one }
        SelectObject(WndDc, RedBrushOld);
        DeleteObject(RedBrush);

        { and the whole thing again with a pattern }
        GreenHatchBrush := CreateHatchBrush(HS_BDIAGONAL, RGB(0, 255, 0));
        GreenHatchBrushOld := SelectObject(WndDC, GreenHatchBrush);
        RectAngle(WndDC, 120, 10, 140, 90);
        { Restore old brush and delete used one }
        SelectObject(WndDC, GreenHatchBrushOld);
        DeleteObject(GreenHatchBrush);

        { and again with a different pen }
        Pen := CreatePen(PS_DOT, 1, RGB(0, 0, 255));
        SetBkMode(WndDC, TRANSPARENT);
        PenOld := SelectObject(WndDC, Pen);
        RectAngle(WndDC, 160, 10, 180, 90);
        SelectObject(WndDC, PenOld);
        DeleteObject(Pen);

        { Ellipse }
        Ellipse(WndDC, 30, 110, 180, 200);
        { Kreis }
        Ellipse(WndDC, 80, 130, 130, 180);

        { Chord }
        Chord(WndDC, 220, 110, 300, 200, 280, 120, 190, 230);

        { Pie }
        Pie(WndDC, 300, 110, 500, 200, 310, 110, 200, 260);

        { RoundRect }
        RoundRect(WndDC, 30, 220, 180, 350, 35, 35);
      EndPaint(hWnd, ps);
    end;
    WM_DESTROY: PostQuitMessage(0);
  else
    Result := DefWindowProc(hWnd, uMsg, wParam, lParam);
  end;
end;

var
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
  wc.hIcon      := LoadIcon(0, IDI_APPLICATION);
  wc.hCursor    := LoadCursor(0, IDC_ARROW);

  RegisterClassEx(wc);
  CreateWindowEx(0, ClassName, AppName, WS_CAPTION or WS_VISIBLE or WS_SYSMENU,
  	CW_USEDEFAULT, CW_USEDEFAULT, WindowWidth, WindowHeight, 0, 0, hInstance, nil);

  while true do
  begin
    if not GetMessage(msg, 0, 0, 0) then
      break;
    TranslateMessage(msg);
    DispatchMessage(msg);
  end;
  ExitCode := msg.wParam;
end.
