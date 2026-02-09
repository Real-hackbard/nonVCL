program accel;

{.DEFINE ACCEL_RESOURCE}

{$IFDEF ACCEL_RESSOURCE}
  {$R accel.res}
{$ENDIF}

uses
  Windows, Messages;

const
  ClassName       = 'Accel_WndClass';
  AppName         = 'Shortcuts';
  WindowWidth     = 200;
  WindowHeight    = 150;
  IDC_CLOSE       = 1;
  IDC_STATIC      = 2;
  IDC_ACCEL_SC    = 1001;
  IDC_ACCEL_CLOSE = 1002;

var
  hWndMain        : DWORD;
  hClose          : DWORD;
  hStatic         : DWORD;
  hAccelTbl       : DWORD;
  hWndFont	  : HGDIOBJ;


function WndProc(wnd: HWND; uMsg: UINT; wp: wParam; lp: LParam):
  lresult; stdcall;
var
  x, y : integer;
begin
  Result := 0;
  case uMsg of
    WM_CREATE:
      begin
        x := GetSystemMetrics(SM_CXSCREEN);
        y := GetSystemMetrics(SM_CYSCREEN);
        MoveWindow(wnd, (x div 2) - (WindowWidth div 2),
          (y div 2) - (WindowHeight div 2),
          WindowWidth, WindowHeight, true);

        hClose := CreateWindowEx(WS_EX_CLIENTEDGE, 'BUTTON', '&Close',
          WS_VISIBLE or WS_CHILD, 45, 75, 100, 28, wnd, IDC_CLOSE, hInstance, nil);
        hStatic := CreateWindowEx(0, 'STATIC', 'Press Strg+S', WS_VISIBLE or
          WS_CHILD or SS_CENTER or SS_SUNKEN, 20, 25, 150, 20, wnd, IDC_STATIC,
          hInstance, nil);

        hWndFont := GetStockObject(DEFAULT_GUI_FONT);
        if(hWndFont <> 0) then
          begin
            SendMessage(hClose,WM_SETFONT,hWndFont,1);
            SendMessage(hStatic,WM_SETFONT,hWndFont,1);
          end;
      end;
    WM_DESTROY:
      begin
        DeleteObject(hWndFont);
        PostQuitMessage(0);
      end;
    WM_COMMAND:
      case HIWORD(wp) of
        BN_CLICKED:
          if(LOWORD(wp) = IDC_CLOSE) then
            SendMessage(wnd,WM_CLOSE,0,0);
        1: // Query shortcut
          case LOWORD(wp) of
            IDC_ACCEL_CLOSE:
              SendMessage(wnd, WM_CLOSE, 0, 0);
            IDC_ACCEL_SC:
              Messagebox(wnd, 'Strg+S pressed', 'Shortcut', MB_ICONINFORMATION);
          end;
      end;
    else
      Result := DefWindowProc(wnd,uMsg,wp,lp);
  end;
end;

var
  wc : TWndClassEx = (
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
  msg : TMsg;
{$IFNDEF ACCEL_RESSOURCE}
  AccelTable : array[0..1]of TAccel;
{$ENDIF}

begin
  wc.hInstance  := hInstance;
  wc.hIcon      := LoadIcon(hInstance, MAKEINTRESOURCE(100));
  wc.hCursor    := LoadCursor(0, IDC_ARROW);

  RegisterClassEx(wc);
  hWndMain := CreateWindowEx(0, ClassName, AppName, WS_CAPTION or WS_VISIBLE or
    WS_SYSMENU, Integer(CW_USEDEFAULT), Integer(CW_USEDEFAULT), WindowWidth,
    WindowHeight, 0, 0, hInstance, nil);

{$IFDEF ACCEL_RESSOURCE}
  // Load table with shortcuts
  hAccelTbl := LoadAccelerators(hInstance, MAKEINTRESOURCE(1000));
{$ELSE}
  // Define shortcut #1 (CTRL+S)
  AccelTable[0].fVirt := FCONTROL or FVIRTKEY;
  AccelTable[0].key   := WORD('S');
  AccelTable[0].cmd   := IDC_ACCEL_SC;

  // Define shortcut #2 (ALT+S)
  AccelTable[1].fVirt := FALT or FVIRTKEY;
  AccelTable[1].key   := WORD('S');
  AccelTable[1].cmd   := IDC_ACCEL_CLOSE;

  // Create a shortcut table
  hAccelTbl           := CreateAcceleratorTable(AccelTable,2);
{$ENDIF}

  while(GetMessage(msg, 0, 0, 0)) do
    begin
      if(TranslateAccelerator(hWndMain, hAccelTbl, msg) = 0) then
        begin
          TranslateMessage(msg);
          DispatchMessage(msg);
        end;
    end;

{$IFNDEF ACCEL_RESSOURCE}
  // Share shortcut table
  DestroyAcceleratorTable(hAccelTbl);
{$ENDIF}

  ExitCode := msg.wParam;
end.
