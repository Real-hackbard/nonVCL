program trackbar;

uses
  Windows,
  Messages,
  CommCtrl;

const
  ClassName = 'Trackbar_WndClass';
  AppName = 'Trackbar-Demo';
  WindowWidth = 300;
  WindowHeight = 220;

var
  hredTB, hgreenTB, hblueTB: Cardinal;

{ GetLastError }
function DisplayErrorMsg(hWnd: THandle): DWORD;
var
  szBuffer: array[0..255] of Char;
begin
  FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, nil, GetLastError, 0, szBuffer,
    sizeof(szBuffer), nil);
  MessageBox(hWnd, szBuffer, 'Error', MB_ICONSTOP);
  result := GetLastError;
end;

function WndProc(hWnd: HWND; uMsg: UINT; wParam: wParam; lParam: LParam):
  lresult; stdcall;
var
  x, y : integer;
  red, green, blue: Integer;
  ps: TPAINTSTRUCT;
  dc: HDC;
  rect: TRECT;
  brush: HBRUSH;
  color, s: array[0..15] of Char;
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

      hredTB := CreateWindowEx(0, 'msctls_trackbar32', '', WS_VISIBLE or WS_CHILD
        or WS_TABSTOP or TBS_TOP or TBS_AUTOTICKS or TBS_TOOLTIPS, 10, 15, 275, 35, hWnd, 0, hInstance, nil);
      SendMessage(hredTB, TBM_SETRANGE, Integer(TRUE), MAKELONG(0,255));  // Set area
      SendMessage(hredTB, TBM_SETPOS, Integer(TRUE), 40);  // set current position
      SendMessage(hredTB, TBM_SETTICFREQ, 20, 0);  { requires TBS_AUTOTICKS }
      SendMessage(hredTB, TBM_SETLINESIZE, 0, 5);  // Step size for the arrow keys
      SendMessage(hredTB, TBM_SETPAGESIZE, 0, 20);  // Step size for the Page Up keys
                                               // and when the trackbar is clicked

      hgreenTB := CreateWindowEx(0, 'msctls_trackbar32', '', WS_VISIBLE or WS_CHILD
        or WS_TABSTOP or TBS_BOTH or TBS_AUTOTICKS or TBS_TOOLTIPS, 10, 60, 275, 35, hWnd, 0, hInstance, nil);
      SendMessage(hgreenTB, TBM_SETRANGE, Integer(TRUE), MAKELONG(0,255));
      SendMessage(hgreenTB, TBM_SETPOS, Integer(TRUE), 80);
      SendMessage(hgreenTB, TBM_SETTICFREQ, 20, 0);
      SendMessage(hgreenTB, TBM_SETLINESIZE, 0, 5);
      SendMessage(hgreenTB, TBM_SETPAGESIZE, 0, 20);

      hblueTB := CreateWindowEx(0, 'msctls_trackbar32', '', WS_VISIBLE or WS_CHILD
        or WS_TABSTOP or TBS_AUTOTICKS or TBS_TOOLTIPS, 10, 105, 275, 35, hWnd, 0, hInstance, nil);
      SendMessage(hblueTB, TBM_SETRANGE, Integer(TRUE), MAKELONG(0,255));
      SendMessage(hblueTB, TBM_SETPOS, Integer(TRUE), 120);
      SendMessage(hblueTB, TBM_SETTICFREQ, 20, 0);
      SendMessage(hblueTB, TBM_SETLINESIZE, 0, 5);
      SendMessage(hblueTB, TBM_SETPAGESIZE, 0, 20);

      SetFocus(hredTB);
    end;
    WM_PAINT:
    begin
      dc := BeginPaint(hWnd, ps);
      red := Sendmessage(hredTB, TBM_GETPOS, 0, 0);
      green := Sendmessage(hgreenTB, TBM_GETPOS, 0, 0);
      blue := Sendmessage(hblueTB, TBM_GETPOS, 0, 0);
      rect.Top := 160;
      rect.Left := 0;
      rect.Bottom := WindowHeight;
      rect.Right := WindowWidth;
      brush := CreateSolidBrush(RGB(red, green, blue));
      FillRect(dc, rect, brush);

      SetBkMode(dc, TRANSPARENT);
      SetTextColor(dc, RGB(255-red, 255-green, 255-blue));
      ZeroMemory(@color, sizeof(color));
      lstrcpy(s, 'Rot: ');
      wvsprintf(color, '%d', PChar(@red));
      lstrcat(s , color);
      TextOut(dc, 10, 170, s, lstrlen(s));
      lstrcpy(s, 'Grün: ');
      wvsprintf(color, '%d', PChar(@green));
      lstrcat(s , color);
      TextOut(dc, 75, 170, s, lstrlen(s));
      lstrcpy(s, 'Blau: ');
      wvsprintf(color, '%d', PChar(@blue));
      lstrcat(s , color);
      TextOut(dc, 150, 170, s, lstrlen(s));


      EndPaint(hWnd, ps);
    end;
    WM_HSCROLL:  // is sent when the slider position changes
    begin
      case LoWord(wParam) of  // LoWord contains the corresponding notification codes.
        TB_THUMBTRACK,  // pulling the "slider"
        TB_TOP,  // Pos1
        TB_BOTTOM,   // Ende
        TB_LINEUP,  // Left/right arrow keys
        TB_LINEDOWN,  // Up/down arrow keys
        TB_PAGEDOWN,  // Clicked down the image and into the bar.
        TB_PAGEUP:  // Image clicked on & in the bar
        begin
          InvalidateRect(hWnd, nil, TRUE);  // Declare window invalid -> redraw
        end;
      end;
    End;
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
  hwndMain: Cardinal;
begin
  InitCommonControls;

  wc.hInstance  := hInstance;
  wc.hIcon      := LoadIcon(0, IDI_APPLICATION);
  wc.hCursor    := LoadCursor(0, IDC_ARROW);

  RegisterClassEx(wc);
  hwndMain := CreateWindowEx(0, ClassName, AppName, WS_CAPTION or WS_VISIBLE or
    WS_SYSMENU, Integer(CW_USEDEFAULT),Integer(CW_USEDEFAULT), WindowWidth,
    WindowHeight, 0, 0, hInstance, nil);


  while true do
  begin
    if not GetMessage(msg, 0, 0, 0) then
      break;
    if IsDialogMessage(hWndMain, msg) = FALSE then
    begin
      TranslateMessage(msg);
      DispatchMessage(msg);
    end;
  end;
  ExitCode := msg.wParam;
end.
