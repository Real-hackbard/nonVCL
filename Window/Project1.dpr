program Window;

uses 
   windows,messages;

{$WARNINGS OFF}
{$HINTS OFF}

const
  windowleft: integer = 100;
  windowtop: integer = 100;
  windowwidth: integer = 265;
  windowheight: integer = 202;
  ClassName = 'ATestWndClassEx';

function WndProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM;
lParam: LPARAM): LRESULT; stdcall;
var IDOK: DWORD;
begin
  Result := 0;
  case uMsg OF
    WM_CREATE:
      begin
        IDOK := createwindow('BUTTON', 'OK-Button',
        WS_VISIBLE OR WS_CHILD, 100, 100, 100, 30, hwnd, 0, hInstance,
        NIL);
        if IDOK = INVALID_HANDLE_VALUE then
          MessageBox(hwnd, 'Button nicht erzeugt', 'Meldung', 0);
      end;
    WM_DESTROY:
      begin
        PostQuitMessage(0);
      end;
    WM_COMMAND:
      if hiword(wparam) = BN_CLICKED then
        if loword(wparam) = IDOK then
          MessageBox(hwnd, 'OK Button gedrückt', 'Meldung', 0);
  else
    Result := DefWindowProc(hWnd, uMsg, wParam, lParam);
  end;
end;

var wc: TWndClassEx = (
    cbSize: SizeOf(TWndClassEx);
    style: CS_OWNDC OR CS_HREDRAW OR CS_VREDRAW;
    cbClsExtra: 0;
    cbWndExtra: 0;
    hbrBackground: COLOR_WINDOW;
    lpszMenuName: NIL;
    lpszClassName: ClassName;
    hIconSm: 0; );
{    mainwnd:DWORD;}   //not needed
  msg: TMSG;
  rect: trect;
  deskh, deskw: integer;

(* In Delphi, tagNONCLIENTMETRICS is the internal Windows API
   name for the TNonClientMetrics record (defined in the Winapi.Windows
   unit). It is used to retrieve or set the scalable metrics (sizes
   and fonts) of the non-client area of non-minimized windows, such
   as title bars, menus, and borders.*)

  //ncm: tagNONCLIENTMETRICS;
begin
  wc.hInstance := HInstance;
  wc.hIcon := LoadIcon(HInstance, MAKEINTRESOURCE(1));
  wc.hCursor := LoadCursor(0, IDC_ARROW);
  wc.lpfnWndProc := @WndProc;
  systemparametersinfo(SPI_GETWORKAREA, 0, @rect, 0);
  deskw := rect.Right - rect.Left;
  deskh := rect.Bottom - rect.Top;

  // this section is for older compiler versions of delphi
  //ncm.cbSize := sizeof(ncm);
  //systemparametersinfo(SPI_GETNONCLIENTMETRICS, sizeof(ncm), @ncm, 0);
  //windowwidth := windowleft + windowwidth;
  //windowheight := windowtop + windowheight + ncm.iMenuHeight +
  //ncm.iCaptionHeight;
  //Windowleft := (deskw DIV 2) - (windowwidth DIV 2);
  //8Windowtop := (deskh DIV 2) - (windowheight DIV 2);
  RegisterClassEx(wc);
    {mainwnd:=} CreateWindowEx(WS_EX_WINDOWEDGE OR WS_EX_CONTROLPARENT
    OR WS_EX_APPWINDOW,
    ClassName,
    'Window',
    WS_OVERLAPPED
    OR WS_CAPTION
    OR WS_SYSMENU
    OR WS_MINIMIZEBOX
    OR WS_VISIBLE,
    windowleft,
    windowtop,
    windowwidth,
    windowheight,
    0,
    0,
    hInstance,
    NIL);
  while True do begin
    if not GetMessage(msg, 0, 0, 0) then break; //oops :o)
    translatemessage(msg);
    dispatchmessage(msg);
  end;
  ExitCode := GetLastError;
end.