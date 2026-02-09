program Hotkey;

uses
  Windows, Messages;

const
  szClassname = 'Hotkey-Demo';
  hk_Id = 4052002;
  LogOff_Id = 4711;
  IDC_LABEL1 = 1;
var
  wv : TOSVersionInfo;
  Label1 : HWND;


function WndProc(wnd: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM): lresult; stdcall;
begin
  Result := 0;

  case uMsg of
    WM_CREATE:
      begin
        Label1 := CreateWindowEx(0, 'STATIC', 'Hotkey STRG+ALT+H',
          WS_VISIBLE or WS_CHILD, 15, 25, 160, 20, Wnd, IDC_LABEl1, hInstance,
          nil);

        if(RegisterHotKey(wnd,hk_Id,MOD_ALT xor MOD_CONTROL,WORD('H'))) then
          MessageBox(0,'Hotkey registered!',@szClassname[1],MB_OK or MB_ICONINFORMATION);

        // Find out Windows version
        wv.dwOSVersionInfoSize := sizeof(TOSVersionInfo);
        GetVersionEx(wv);

        // Register hotkey WIN+L for Win only
        if(wv.dwPlatformId = VER_PLATFORM_WIN32_WINDOWS) then
         RegisterHotKey(wnd,LogOff_Id,MOD_WIN,WORD('L'))
      end;
    WM_DESTROY:
      begin
        UnRegisterHotKey(wnd,LogOff_Id);
        UnRegisterHotKey(wnd,hk_Id);
        DestroyWindow(Label1);
        PostQuitMessage(0);
      end;
    WM_HOTKEY:
      case wp of
        hk_Id:
          MessageBox(0,'They tried the hotkey',@szClassname[1],MB_OK);
        LogOff_Id:
          begin
            SendMessage(wnd,WM_CLOSE,0,0);
            ExitWindowsEx(EWX_LOGOFF,0);
          end;
      end;
    else
      Result := DefWindowProc(wnd, uMsg, wp, lp);
  end;
end;

var
  {Window class structure}
  wc   : TWndClassEx = (
    cbSize          : SizeOf(TWndClassEx);
    Style           : CS_HREDRAW or CS_VREDRAW;
    lpfnWndProc     : @WndProc;
    cbClsExtra      : 0;
    cbWndExtra      : 0;
    hbrBackground   : COLOR_APPWORKSPACE;
    lpszMenuName    : nil;
    lpszClassName   : szClassname;
    hIconSm         : 0;
  );
  msg  : TMsg;
  aWnd : HWND;

begin
  wc.hInstance  := hInstance;
  wc.hIcon      := LoadIcon(0,IDI_APPLICATION);
  wc.hCursor    := LoadCursor(0,IDC_ARROW);
  if(RegisterClassEx(wc) = 0) then exit;

  aWnd := CreateWindowEx(0, szClassname, szClassname, WS_CAPTION or WS_VISIBLE or WS_SYSMENU
    or WS_MINIMIZEBOX or WS_MAXIMIZEBOX or WS_SIZEBOX, integer(CW_USEDEFAULT),
    integer(CW_USEDEFAULT), 200, 150, 0, 0, hInstance, nil);
  if(aWnd = 0) then exit;
  ShowWindow(aWnd,SW_SHOW);
  UpdateWindow(aWnd);

  while GetMessage(msg,0,0,0) do
    begin
      TranslateMessage(msg);
      DispatchMessage(msg);
    end;

  ExitCode := msg.wParam;
end.