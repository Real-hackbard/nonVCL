program SysBitmaps;

uses
  Windows,
  Messages,
  CommCtrl;

const
  ClassName    = 'Toolbar2Class';
  AppName      = 'Toolbar2-Demo';
  WindowWidth  = 500;
  WindowHeight = 150;


const
  IDC_TOOLBAR = 1;
  IDC_DUMMY   = 1;

var
  tbButtons : array[0..7] of TTBButton = (
    (iBitmap   : STD_FILENEW;
     idCommand : IDC_DUMMY;
     fsState   : TBSTATE_ENABLED;
     fsStyle   : TBSTYLE_BUTTON;
     dwData    : 0;
     iString   : 0;
    ),
    (iBitmap   : STD_FILEOPEN;
     idCommand : IDC_DUMMY;
     fsState   : TBSTATE_ENABLED;
     fsStyle   : TBSTYLE_BUTTON;
     dwData    : 0;
     iString   : 0;
    ),
    (iBitmap   : STD_FILESAVE;
     idCommand : IDC_DUMMY;
     fsState   : TBSTATE_ENABLED;
     fsStyle   : TBSTYLE_BUTTON;
     dwData    : 0;
     iString   : 0;
    ),
    (iBitmap   : -1;
     idCommand : 0;
     fsState   : TBSTATE_ENABLED;
     fsStyle   : TBSTYLE_SEP;
     dwData    : 0;
     iString   : 0;
    ),
    (iBitmap   : STD_CUT;
     idCommand : IDC_DUMMY;
     fsState   : TBSTATE_ENABLED;
     fsStyle   : TBSTYLE_BUTTON;
     dwData    : 0;
     iString   : 0;
    ),
    (iBitmap   : STD_COPY;
     idCommand : IDC_DUMMY;
     fsState   : TBSTATE_ENABLED;
     fsStyle   : TBSTYLE_BUTTON;
     dwData    : 0;
     iString   : 0;
    ),
    (iBitmap   : STD_PASTE;
     idCommand : IDC_DUMMY;
     fsState   : TBSTATE_ENABLED;
     fsStyle   : TBSTYLE_BUTTON;
     dwData    : 0;
     iString   : 0;
    ),
    (iBitmap   : STD_DELETE;
     idCommand : IDC_DUMMY;
     fsState   : TBSTATE_ENABLED;
     fsStyle   : TBSTYLE_BUTTON;
     dwData    : 0;
     iString   : 0;
    ));


function WndProc(hWnd: HWND; uMsg: UINT; wParam: wParam; lParam: LParam):
  lresult; stdcall;
var
  x, y      : integer;
  hToolbar  : cardinal;
  bBmp      : TBAddBitmap;
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

      { Create toolbar }
      hToolbar   := CreateToolbarEx(hWnd,WS_CHILD or WS_VISIBLE or
        CCS_ADJUSTABLE, IDC_TOOLBAR,
        0, 0, 0, @tbButtons, 8, 0, 0, 0, 0, sizeof(TTBButton));

      { Loading system bitmaps }
      bBmp.hInst := HINST_COMMCTRL;
      bBmp.nID   := IDB_STD_SMALL_COLOR;

      { Assign system bitmaps }
      SendMessage(hToolbar,TB_ADDBITMAP,0,integer(@bBmp));
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
  InitCommonControls;

  wc.hInstance  := hInstance;
  wc.hIcon      := LoadIcon(0, IDI_APPLICATION);
  wc.hCursor    := LoadCursor(0, IDC_ARROW);

  RegisterClassEx(wc);
  CreateWindowEx(0, ClassName, AppName, WS_CAPTION or WS_VISIBLE or
    WS_SYSMENU or WS_MINIMIZEBOX, Integer(CW_USEDEFAULT),
    Integer(CW_USEDEFAULT), WindowWidth, WindowHeight, 0,
    0, hInstance, nil);

  while true do
  begin
    if not GetMessage(msg, 0, 0, 0) then
      break;
    begin
      TranslateMessage(msg);
      DispatchMessage(msg);
    end;
  end;
  ExitCode := msg.wParam;
end.