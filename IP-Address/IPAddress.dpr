program IPAddress;

{.$DEFINE EN_CHANGE}

uses
  Windows,
  Messages,
  CommCtrl,
  MSysUtils in 'MSysUtils.pas';


const
  szClassName = 'IPWndClass';
  szAppName   = 'IP-Address Control';


//
// WndProc
//
const
  IDC_IPCTRL = 1;
  IDC_CLEAR  = 2;
  IDC_GET    = 3;
  IDC_FOCUS  = 4;
  IDC_LABEL  = 5;
var
  hIpAddr,
  hClearBtn,
  hGetBtn,
  hFocusBtn,
  hLabel     : HWND;
  hWndFont   : HGDIOBJ;
  IpStr      : string;
  iFocus     : integer = -1;

function WndProc(wnd: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM): LRESULT; stdcall;
var
  curIp : dword;
begin
  Result := 0;

  case uMsg of
    WM_CREATE:
      begin
        // IP-Adresse
        hIpAddr := CreateWindowEx(WS_EX_CLIENTEDGE,WC_IPADDRESS,nil,
          WS_VISIBLE or WS_CHILD,10,20,120,21,wnd,IDC_IPCTRL,
          hInstance,nil);
        if(hIpAddr <> 0) then
          SendMessage(hIpAddr,IPM_SETADDRESS,0,MAKEIPADDRESS(127,0,0,1));

        // Create Label
        hLabel := CreateWindowEx(WS_EX_CLIENTEDGE,'STATIC',nil,
          WS_VISIBLE or WS_CHILD,140,20,190,21,wnd,IDC_LABEL,
          hInstance,nil);

        // Create Buttons
        hClearBtn := CreateWindowEx(0,'BUTTON','Remove IP-Adress',
          WS_VISIBLE or WS_CHILD,14,50,110,23,wnd,IDC_CLEAR,
          hInstance,nil);
        hGetBtn := CreateWindowEx(0,'BUTTON','Read IP-Adress',
          WS_VISIBLE or WS_CHILD,180,50,110,23,wnd,IDC_GET,
          hInstance,nil);
        hFocusBtn := CreateWindowEx(0,'BUTTON','Focus field',
          WS_VISIBLE or WS_CHILD,14,80,110,23,wnd,IDC_FOCUS,
          hInstance,nil);

        // Buttons deactivate?
        if(hIpAddr = 0) then
          begin
            EnableWindow(hClearBtn,false);
            EnableWindow(hGetBtn,false);
            EnableWindow(hFocusBtn,false);
          end;

        // Font
        hWndFont := GetStockObject(DEFAULT_GUI_FONT);
        if(hWndFont <> 0) then
          begin
            SendMessage(hIpAddr,WM_SETFONT,hWndFont,1);
            SendMessage(hLabel,WM_SETFONT,hWndFont,1);
            SendMessage(hClearBtn,WM_SETFONT,hWndFont,1);
            SendMessage(hGetBtn,WM_SETFONT,hWndFont,1);
            SendMessage(hFocusBtn,WM_SETFONT,hWndFont,1);
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
          case LOWORD(wp) of
            IDC_CLEAR:
              begin
                // IP-Adresse remove
                SendMessage(hIpAddr,IPM_CLEARADDRESS,0,0);

                // Labelcontent remove
                IpStr := '';
                SendMessage(hLabel,WM_SETTEXT,0,LPARAM(@IpStr[1]));

                // Reset focus value
                iFocus := -1;
              end;
            IDC_GET:
              begin
                // get IP-Adresse
                SendMessage(hIpAddr,IPM_GETADDRESS,0,LPARAM(@curIp));

                // ... format ...
                IpStr := Format('%d.%d.%d.%d',
                  [FIRST_IPADDRESS(curIp),SECOND_IPADDRESS(curIp),
                   THIRD_IPADDRESS(curIp),FOURTH_IPADDRESS(curIp)]);

                // ... and display in the label
                SendMessage(hLabel,WM_SETTEXT,0,LPARAM(@IpStr[1]));
              end;
            IDC_FOCUS:
              begin
                iFocus := (iFocus + 1) mod 4;
                SendMessage(hIpAddr,IPM_SETFOCUS,iFocus,0);
              end;
          end;
{$IFDEF EN_CHANGE}
        EN_CHANGE:
          begin
            SendMessage(hIpAddr,IPM_GETADDRESS,0,LPARAM(@curIp));

            // ... format ...
            IpStr := Format('%d.%d.%d.%d',
              [FIRST_IPADDRESS(curIp),SECOND_IPADDRESS(curIp),
               THIRD_IPADDRESS(curIp),FOURTH_IPADDRESS(curIp)]);

            // ... and display in the label
            SendMessage(hLabel,WM_SETTEXT,0,LPARAM(@IpStr[1]));
          end;
{$ENDIF}
      end;
{$IFNDEF EN_CHANGE}
    WM_NOTIFY:
      // The message IPN_FIELDCHANGED is triggered when
      //   a) the value of a field was changed
      //   b) the current field was left
      if(PNMIpAddress(lp)^.hdr.Code = IPN_FIELDCHANGED) then
        begin
          IpStr := Format('Field "%d" contains value "%d"',
            [PNMIpAddress(lp)^.iField + 1,
             PNMIpAddress(lp)^.iValue]);
          SendMessage(hLabel,WM_SETTEXT,0,LPARAM(@IpStr[1]));

          // Which field is the current one?
          // (for focusing)
          iFocus := PNMIpAddress(lp)^.iField;
        end;
{$ENDIF}
    else
      Result := DefWindowProc(wnd,uMsg,wp,lp);
  end;
end;

//
// MAIN
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
    lpszClassName : szClassName;
    hIconSm       : 0;
  );
  msg : TMsg;
  icc : TInitCommonControlsEx = (
    dwSize : sizeof(TInitCommonControlsEx);
    dwICC  : ICC_INTERNET_CLASSES;
  );
  aWnd : HWND;

begin
  // for IP control
  InitCommonControlsEx(icc);

  // Register window class
  wc.hInstance  := hInstance;
  wc.hIcon      := LoadIcon(0, IDI_APPLICATION);
  wc.hCursor    := LoadCursor(0, IDC_ARROW);
  if(RegisterClassEx(wc) = 0) then exit;

  // Create window
  aWnd := CreateWindowEx(0,szClassName,szAppName,WS_CAPTION or WS_VISIBLE or WS_SYSMENU,
    integer(CW_USEDEFAULT),integer(CW_USEDEFAULT),350,140,0,0,
    hInstance,nil);
  if(aWnd = 0) then exit;
  ShowWindow(aWnd,SW_SHOW);
  UpdateWindow(aWnd);

  // Message loop
  while(GetMessage(msg,0,0,0)) do
    begin
      TranslateMessage(msg);
      DispatchMessage(msg);
    end;
end.