program Tooltipps;

{.$DEFINE ENABLETITLE}
{.$DEFINE BALLOONSTYLE}
{.$DEFINE CHANGECOLOR}

uses
  Windows,
  Messages,
  CommCtrl,
  CommCtrl_Fragment in 'CommCtrl_Fragment.pas';

const
  // Basic settings
  szClassname  = 'TTipp_WndClass';
  szAppname    = 'Tooltipp-Demo';
  wWidth       = 255;
  wHeight      = 150;

  // Tooltip texts
  TIPP_EDIT    = 'Enter a tooltip here.';
  TIPP_CHANGE  = 'Changes the tooltip of the "Close" button.';
  TIPP_CLOSE   = 'Exit the program with ALT+S';

  // Control IDs
  IDC_EDIT     = 1;
  IDC_CHANGE   = 2;
  IDC_CLOSE    = 3;
  IDC_CHECKB   = 4;

  // Accelerator IDs
  ACCEL_CHANGE = 1000;
  ACCEL_CLOSE  = 1001;

var
  hToolTip     : HWND;

//
// Tooltip procedures
//
procedure AddToolTip(wnd: HWND; hInst: longword; lpText: pchar);
var
  ti : TToolInfo;
  r  : TRect;
begin
  if(wnd <> 0) and (GetClientRect(wnd,r)) then
    begin
      fillchar(ti,sizeof(TToolInfo),0);

      ti.cbSize   := sizeof(TToolInfo);
      ti.uFlags   := TTF_SUBCLASS or TTF_IDISHWND;
      ti.hwnd     := wnd;
      ti.uId      := wnd;
      ti.Rect     := r;
      ti.hInst    := hInst;
      ti.lpszText := lpText;

      SendMessage(hToolTip,TTM_ADDTOOL,0,LPARAM(@ti));
    end;
end;

procedure UpdateToolTip(wnd: HWND; hInst: longword; lpText: pchar);
var
  ti : TToolInfo;
begin
  if(wnd <> 0) then
    begin
      fillchar(ti,sizeof(TToolInfo),0);

      ti.cbSize   := sizeof(TToolInfo);
      ti.hwnd     := wnd;
      ti.uId      := wnd;
      ti.hInst    := hInst;
      ti.lpszText := lpText;

      SendMessage(hToolTip,TTM_UPDATETIPTEXT,0,LPARAM(@ti));
    end;
end;

//
// WndProc
//
var
  hCloseBtn,
  hChangeBtn,
  hEdit,
  hCheckBox : HWND;
  hWndFont  : HGDIOBJ;
  buffer    : array[0..255]of char;
  bFlag     : boolean = false;


function WndProc(wnd: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM): LRESULT; stdcall;
var
  x, y  : integer;
{$IFDEF CHANGECOLOR}
  z     : cardinal;
{$ENDIF}
begin
  Result := 0;

  case uMsg of
    WM_CREATE:
      begin
        // Center window
        x := GetSystemMetrics(SM_CXSCREEN);
        y := GetSystemMetrics(SM_CYSCREEN);
        MoveWindow(wnd, (x div 2) - (wWidth div 2),
          (y div 2) - (wHeight div 2),
          wWidth, wHeight, true);

        // Create controls
        hEdit := CreateWindowEx(WS_EX_CLIENTEDGE, 'EDIT', {TIPP_CLOSE}nil, WS_VISIBLE or
          WS_CHILD, 20, 25, 210, 21, wnd, IDC_EDIT, hInstance, nil);

        hChangeBtn := CreateWindowEx(0, 'BUTTON', '&Change tip',
          WS_VISIBLE or WS_CHILD, 20, 60, 100, 23, wnd, IDC_CHANGE,
          hInstance, nil);

        hCloseBtn := CreateWindowEx(0, 'BUTTON', '&Close',
          WS_VISIBLE or WS_CHILD or BS_DEFPUSHBUTTON, 130, 60, 100, 23, wnd, IDC_CLOSE,
          hInstance, nil);

        hCheckBox := CreateWindowEx(0, 'BUTTON', 'Enable tips',
          WS_VISIBLE or WS_CHILD or BS_AUTOCHECKBOX, 20, 90, 210, 21, wnd, IDC_CHECKB,
          hInstance, nil);
        SendMessage(hCheckBox,BM_SETCHECK,BST_CHECKED,0);

        // Create and assign a font
        hWndFont := GetStockObject(DEFAULT_GUI_FONT);
        if(hWndFont <> 0) then
          begin
            SendMessage(hEdit,WM_SETFONT,hWndFont,1);
            SendMessage(hChangeBtn,WM_SETFONT,hWndFont,1);
            SendMessage(hCloseBtn,WM_SETFONT,hWndFont,1);
            SendMessage(hCheckBox,WM_SETFONT,hWndFont,1);
          end;

        // Create tooltip window
        hToolTip := CreateWindowEx(WS_EX_TOPMOST, TOOLTIPS_CLASS, nil,
          TTS_ALWAYSTIP or TTS_NOPREFIX or WS_POPUP
          {$IFDEF BALLOONSTYLE} or TTS_BALLOON {$ENDIF},
          integer(CW_USEDEFAULT), integer(CW_USEDEFAULT), integer(CW_USEDEFAULT),
          integer(CW_USEDEFAULT), wnd, 0, hInstance, nil);

        if(hToolTip <> 0) then
          begin
            // Set tooltip as topmost window
            SetWindowPos(hToolTip, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or
              SWP_NOSIZE or SWP_NOACTIVATE);

{$IFDEF ENABLETITLE}
            // New tooltip style, including title
            fillchar(buffer,sizeof(buffer),#0); lstrcpy(buffer,szAppname);
            SendMessage(hToolTip,TTM_SETTITLE,TTI_INFO,LPARAM(@buffer));
{$ENDIF}

            // Assign tool tips
            AddToolTip(hEdit,hInstance,TIPP_EDIT);
            AddToolTip(hChangeBtn,hInstance,TIPP_CHANGE);
            AddToolTip(hCloseBtn,hInstance,TIPP_CLOSE);

{$IFDEF CHANGECOLOR}
            // Change tip colors
            z := $00ffffff; SendMessage(hToolTip,TTM_SETTIPBKCOLOR,z,0);
            z := $00800000; SendMessage(hToolTip,TTM_SETTIPTEXTCOLOR,z,0);
{$ENDIF}
          end;
      end;
    WM_DESTROY:
      begin
        DeleteObject(hWndFont);
        PostQuitMessage(0);
      end;
    WM_COMMAND:
      case HIWORD(wp) of
        1:
          case LOWORD(wp) of
            ACCEL_CHANGE:
              SendMessage(wnd,WM_COMMAND,MAKELONG(IDC_CHANGE,BN_CLICKED),0);
            ACCEL_CLOSE:
              SendMessage(wnd,WM_CLOSE,0,0);
          end;
        BN_CLICKED:
          case LOWORD(wp) of
            IDC_CLOSE:
              SendMessage(wnd,WM_CLOSE,0,0);
            IDC_CHANGE:
              begin
                // Retrieve text from the edit field
                fillchar(buffer,sizeof(buffer),#0);
                SendMessage(hEdit,WM_GETTEXT,256,LPARAM(@buffer));

                // Change the tooltip of the "Close" button :o)
                if(buffer[0] <> #0) then
                  UpdateToolTip(hCloseBtn,hInstance,buffer);
              end;
            IDC_CHECKB:
              begin
                // Query status
                bFlag := SendMessage(hCheckBox,BM_GETCHECK,0,0) = BST_CHECKED;

                // Enable or disable tooltips
                SendMessage(hToolTip,TTM_ACTIVATE,WPARAM(bFlag),0);
              end;
          end;
        EN_CHANGE:
          case LOWORD(wp) of
            IDC_EDIT:
              begin
                // Retrieve text from the edit field
                fillchar(buffer,sizeof(buffer),#0);
                SendMessage(hEdit,WM_GETTEXT,256,LPARAM(@buffer));

                // Disable the button if the edit field is empty.
                EnableWindow(hChangeBtn,buffer[0] <> #0);
              end;
          end;
      end;
    else
      Result := DefWindowProc(wnd,uMsg,wp,lp);
  end;
end;

//
// Main
//
var
  wc : TWndClassEx = (
    cbSize        : SizeOf(TWndClassEx);
    Style         : CS_HREDRAW or CS_VREDRAW;
    lpfnWndProc   : @WndProc;
    cbClsExtra    : 0;
    cbWndExtra    : 0;
    hbrBackground : COLOR_APPWORKSPACE;
    lpszMenuName  : nil;
    lpszClassName : szClassname;
    hIconSm       : 0;
  );
  msg : TMsg;
  AccelTbl : array[0..1]of TAccel;
  wndMain, hAccelTbl : dword;

begin
  // For tooltips, go to "InitCommonControls".
  InitCommonControls;

  // Add window class
  wc.hInstance := hInstance;
  wc.hIcon     := LoadIcon(0,IDI_APPLICATION);
  wc.hCursor   := LoadCursor(0, IDC_ARROW);

  // Register window class, & create window
  if(RegisterClassEx(wc) = 0) then exit;
  wndmain := CreateWindowEx(0, szClassname, szAppname, WS_CAPTION or WS_VISIBLE or
    WS_SYSMENU, integer(CW_USEDEFAULT), integer(CW_USEDEFAULT), wWidth,
    wHeight, 0, 0, hInstance, nil);
  if(wndmain = 0) then exit;
  ShowWindow(wndmain,SW_SHOW);
  UpdateWindow(wndmain);

  // Generate accelerator table
  AccelTbl[0].fVirt := FALT or FVIRTKEY;
  AccelTbl[0].key   := WORD('T');
  AccelTbl[0].cmd   := ACCEL_CHANGE;
  AccelTbl[1].fVirt := FALT or FVIRTKEY;
  AccelTbl[1].key   := WORD('S');
  AccelTbl[1].cmd   := ACCEL_CLOSE;
  hAccelTbl         := CreateAcceleratorTable(AccelTbl,2);

  while(GetMessage(msg,0,0,0)) do
    begin
      if(TranslateAccelerator(wndmain, hAccelTbl, msg) = 0) then
        begin
          TranslateMessage(msg);
          DispatchMessage(msg);
        end;
    end;

  // Release accelerator table
  DestroyAcceleratorTable(hAccelTbl);

  ExitCode := msg.wParam;
end.