program OnMinimize;

uses
  Windows, Messages, ShellAPI;

{$R OnMinimize.res}



const
  szClassname = 'OnMinimize-Demo';

  IDM_SHOW    = 1;
  IDM_EXIT    = 2;

  WM_TNAMSG   = WM_USER + 10;

var
  NID         : TNotifyIconData =
    (cbSize:sizeof(TNotifyIconData);
     uID:1;
     uFlags:NIF_MESSAGE or NIF_ICON or NIF_TIP;
     uCallbackMessage:WM_TNAMSG;
     hIcon:0;
     szTip:szClassname;);


function WndProc(wnd: HWND; uMsg: UINT; wp: wParam; lp: LParam): LRESULT;
  stdcall;
var
  hm : HMENU;
  p  : TPoint;
begin
  Result := 0;

  case uMsg of
    WM_CREATE:
      begin
        NID.wnd   := wnd;
        NID.hIcon := LoadIcon(hInstance,'JIM');
      end;
    WM_TNAMSG:
      case lp of
        WM_RBUTTONUP:
          begin
            hm := CreatePopupMenu;
            AppendMenu(hm,MF_STRING,IDM_SHOW,'anzeigen');
            AppendMenu(hm,MF_STRING,IDM_EXIT,'beenden');

            GetCursorPos(p);
            SetForegroundWindow(wnd);
            TrackPopupMenu(hm,TPM_RIGHTALIGN,p.X,p.Y,0,wnd,nil);

            DestroyMenu(hm);
          end;
        WM_LBUTTONDBLCLK:
          SendMessage(wnd,WM_COMMAND,MAKEWPARAM(IDM_SHOW,BN_CLICKED),0);
      end;
    WM_SIZE:
      if(wp = SIZE_MINIMIZED) then begin
        if(Shell_NotifyIcon(NIM_ADD,@NID)) then
          ShowWindow(wnd,SW_HIDE)
        else
          Result := DefWindowProc(wnd,uMsg,wp,lp);
      end else
        Result := DefWindowProc(wnd,uMsg,wp,lp);
    WM_COMMAND:
      if(HIWORD(wp) = BN_CLICKED) then
        case LOWORD(wp) of
          IDM_SHOW:
            begin
              ShowWindow(wnd,SW_RESTORE);
              Shell_NotifyIcon(NIM_DELETE,@NID);
            end;
          IDM_EXIT:
            SendMessage(wnd,WM_CLOSE,0,0);
        end;
    WM_DESTROY:
      begin
        Shell_NotifyIcon(NIM_DELETE,@NID);
        PostQuitMessage(0);
      end;
    else
      Result := DefWindowProc(wnd,uMsg,wp,lp);
  end;
end;


//
// MAIN
//
var
  msg    : TMsg;
  aWnd   : HWND;
  wc : TWndClassEx =
    (cbSize:sizeof(TWndClassEx);
     Style:CS_HREDRAW or CS_VREDRAW;
     lpfnWndProc:@WndProc;
     cbClsExtra:0;
     cbWndExtra:0;
     lpszMenuName:nil;
     lpszClassName:szClassName;);
begin
  wc.hInstance     := hInstance;
  wc.hbrBackground := GetSysColorBrush(COLOR_3DFACE);
  wc.hIcon         := LoadIcon(hInstance,'JIM');
  wc.hCursor       := LoadCursor(0,IDC_ARROW);
  if(RegisterClassEx(wc) = 0) then exit;

  aWnd := CreateWindowEx(0,szClassname,szClassname,
    WS_SYSMENU or WS_MINIMIZEBOX or WS_VISIBLE,
    300,300,320,320,0,0,hInstance,nil);
  if(aWnd = 0) then exit;
  ShowWindow(aWnd,SW_SHOW);
  UpdateWindow(aWnd);

  while(GetMessage(msg,0,0,0)) do begin
    TranslateMessage(msg);
    DispatchMessage(msg);
  end;
end.