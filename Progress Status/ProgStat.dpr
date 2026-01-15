program ProgStat;

{.$DEFINE USECREATEWINDOWEX}
{.$DEFINE CHANGECOLOR}

{$R resource.res}
{$R statusbar.res}

uses
  Windows,
  Messages,
  CommCtrl,
  CommCtrl_Fragment in 'CommCtrl_Fragment.pas',
  MSysUtils in 'MSysUtils.pas';

const
  ClassName      = 'WndClass';
  AppName        = 'Progressbar-/Statusbar-Demo';
  WindowWidth    = 300;
  WindowHeight   = 145;

  IDC_STATUS     = 1;
  IDC_PROGRESS   = 2;
  IDC_XPPROGRESS = 3;
  IDC_TIMER      = 4;

var
  hwndStatus,
  hwndProgress,
  hwndXP         : HWND;
  hWndFont       : HGDIOBJ;
  hIco           : HICON;
  hwndTimer      : dword;
  i              : integer = 9;


function WndProc(wnd: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM):
  LRESULT; stdcall;
var
  x,
  y          : integer;
  rec        : TRect;
  PanelWidth : array[0..2]of integer;
  buffer     : array[0..255]of char;
begin
  Result     := 0;

  GetClientRect(wnd,rec);
  PanelWidth[0] := 40;
  PanelWidth[1] := rec.Right - rec.Left - 55;
  PanelWidth[2] := -1;

  case uMsg of
    WM_CREATE:
      begin
        // Center window
        x := GetSystemMetrics(SM_CXSCREEN);
        y := GetSystemMetrics(SM_CYSCREEN);
        MoveWindow(wnd,(x div 2) - (WindowWidth div 2),
          (y div 2) - (WindowHeight div 2),
          WindowWidth,WindowHeight,true);

       // Create a status bar with panels
{$IFDEF USECREATEWINDOWEX}
       hwndStatus := CreateWindowEx(0,STATUSCLASSNAME,nil,WS_CHILD or
         WS_VISIBLE or SBT_TOOLTIPS,0,0,0,0,wnd,IDC_STATUS,
         hInstance,nil);
{$ELSE}
       hwndStatus := CreateStatusWindow(WS_CHILD or WS_VISIBLE or
         SBT_TOOLTIPS or SBT_RTLREADING,nil,wnd,IDC_STATUS);
{$ENDIF}

       // divide into panels
       SendMessage(hwndStatus,SB_SETPARTS,3,LPARAM(@PanelWidth));

       // Write text in panels
       buffer := '10';
       SendMessage(hwndStatus,SB_SETTEXT,0,LPARAM(@buffer));
       buffer := 'Panel2';
       SendMessage(hwndStatus,SB_SETTEXT,1,LPARAM(@buffer));
       buffer := 'Panel3';
       SendMessage(hwndStatus,SB_SETTEXT,2 or SBT_NOBORDERS,LPARAM(@buffer));

       // Set tool tip
       SendMessage(hwndStatus,SB_SETTIPTEXT,2,LPARAM(@buffer));

       // Show icon in panel
       hIco := LoadIcon(hInstance,MAKEINTRESOURCE(200));
       if(hIco <> 0) then
         SendMessage(hwndStatus,SB_SETICON,1,hIco);

       // Generate normal progress bar
       hwndProgress := CreateWindowEx(0,PROGRESS_CLASS,nil,
         WS_CHILD or WS_VISIBLE or PBS_SMOOTH,10,30,270,15,wnd,
         IDC_PROGRESS,hInstance,nil);
       SendMessage(hwndProgress,PBM_SETRANGE,0,LPARAM(100 shl 16));
       SendMessage(hwndProgress,PBM_SETSTEP,10,0);

       if (IsWindowsXP) or (IsWindowsVista) then
       begin
         hwndXP := CreateWindowEx(0,PROGRESS_CLASS,nil,
           WS_CHILD or WS_VISIBLE or PBS_MARQUEE,10,60,270,15,wnd,
           IDC_XPPROGRESS,hInstance,nil);

         // Activate marquee style in 40 ms
         SendMessage(hwndXP,PBM_SETMARQUEE,WPARAM(true),40);
       end else
       // no progress bar ...
       begin
         hwndXP:= CreateWindowEx(0,'STATIC',
           'no new progress bar ... ;o)',
           WS_VISIBLE or WS_CHILD,10,60,270,15,wnd,0,hInstance,nil);

        hWndFont := GetStockObject(DEFAULT_GUI_FONT);
        if(hWndFont <> 0) then
          SendMessage(hwndXP,WM_SETFONT,hWndFont,1);
       end;

{$IFDEF CHANGECOLOR}
       SendMessage(hwndProgress,PBM_SETBARCOLOR,0,RGB($90,0,0));
       SendMessage(hwndProgress,PBM_SETBKCOLOR,0,RGB(0,0,0));
{$ENDIF}

       // Generate timer
       hwndTimer := SetTimer(wnd,IDC_TIMER,1000,nil);
      end;
    WM_DESTROY:
      PostQuitMessage(0);
    WM_SIZE:
      MoveWindow(hwndStatus,0,HIWORD(lp),LOWORD(lp),HIWORD(lp),true);
    WM_TIMER:
      begin
        SendMessage(hwndProgress, PBM_STEPIT, 0, 0);

        if(i <> -1) then begin
          wvsprintf(buffer,'%d',pchar(@i));
          SendMessage(hwndStatus,SB_SETTEXT,0,LPARAM(@buffer));
          dec(i);
        end else begin
          KillTimer(wnd, hwndTimer);
          hwndTimer := 0;
          SendMessage(hwndProgress,PBM_SETPOS,0,0);

          buffer := 'done!';
          SendMessage(hwndStatus,SB_SETTEXT,0,LPARAM(@buffer));
        end;
      end;
  else
    Result := DefWindowProc(wnd,uMsg,wp,lp);
  end;
end;


var
  msg : TMsg;
  wc  : TWndClassEx = (
    cbSize:sizeof(TWndClassEx);
    Style:CS_HREDRAW or CS_VREDRAW;
    lpfnWndProc:@WndProc;
    cbClsExtra:0;
    cbWndExtra:0;
    lpszMenuName:nil;
    lpszClassName:ClassName;
    hIconSm:0;);
begin
  InitCommonControls;

  wc.hInstance      := hInstance;
  wc.hIcon          := LoadIcon(hInstance,MAKEINTRESOURCE(100));
  wc.hCursor        := LoadCursor(0,IDC_ARROW);
  wc.hbrBackground  := GetSysColorBrush(COLOR_3DFACE);
  if(RegisterClassEx(wc) = 0) then exit;

  if(CreateWindowEx(0,ClassName,AppName,WS_CAPTION or WS_VISIBLE or WS_SYSMENU,
    integer(CW_USEDEFAULT),integer(CW_USEDEFAULT),WindowWidth,WindowHeight,
    0,0,hInstance,nil) = 0) then exit;

  while GetMessage(msg,0,0,0) do begin
    TranslateMessage(msg);
    DispatchMessage(msg);
  end;

  ExitCode := msg.wParam;
end.