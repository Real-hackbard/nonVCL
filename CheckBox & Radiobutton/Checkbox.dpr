program Checkbox;

{$R resource.res}

uses
  Windows,
  Messages;

const
  ClassName = 'WndClass';
  AppName = 'Checkbox & RadioButton';
  WindowWidth = 225;
  WindowHeight = 210;

const
  IDC_CHKBOX = 2;
  IDC_GROUP = 3;
  IDC_OPT1 = 4;
  IDC_OPT2 = 5;
  IDC_STATIC1 = 6;
  IDC_STATIC2 = 7;

const
  TextFlags  : array[boolean]of string   = ('Unchecked','Checked');
  CheckFlags : array[boolean]of cardinal = (BST_UNCHECKED,BST_CHECKED);

var
  hwndChkBox: DWORD;
  hwndStatic1: DWORD;
  hwndGroup: DWORD;
  hwndOpt1, hwndOpt2: DWORD;
  hwndStatic2: DWORD;
  bCbFlag : boolean;


function WndProc(hWnd: HWND; uMsg: UINT; wParam: wParam; lParam: LParam):
  lresult; stdcall;
var
  x, y : integer;
  buffer: array[0..255] of Char;
begin
  Result := 0;
  case uMsg of
    WM_CREATE:
      begin
        {Center window}
        x := GetSystemMetrics(SM_CXSCREEN);
        y := GetSystemMetrics(SM_CYSCREEN);
        MoveWindow(hWnd, (x div 2) - (WindowWidth div 2),
          (y div 2) - (WindowHeight div 2),
          WindowWidth, WindowHeight, true);

        {Create checkbox}
        hwndChkBox := CreateWindowEx(0, 'BUTTON', '&Checkbox', WS_VISIBLE or
          WS_CHILD or BS_CHECKBOX, 10, 20, 90, 25, hWnd, IDC_CHKBOX,
          hInstance, nil);
        hwndStatic1 := CreateWindowEx(0, 'STATIC', '', WS_VISIBLE or WS_CHILD,
          105, 25, 100, 18, hWnd, IDC_STATIC1, hInstance, nil);

        {Create group box}
        hwndGroup := CreateWindowEx(0, 'BUTTON', 'Optionsgruppe:', WS_VISIBLE or
          WS_CHILD or BS_GROUPBOX, 10, 50, 200, 110, hWnd, IDC_GROUP, hInstance,
          nil);

        {Create radio buttons}
        hwndOpt1 := CreateWindowEx(0, 'BUTTON', 'R&adiobutton1', WS_VISIBLE or
          WS_CHILD or BS_AUTORADIOBUTTON, 25, 75, 125, 25, hWnd, IDC_OPT1,
          hInstance, nil);
        hwndOpt2 := CreateWindowEx(0, 'BUTTON', 'Radio&button2', WS_VISIBLE or
          WS_CHILD or BS_AUTORADIOBUTTON, 25, 100, 125, 25, hWnd, IDC_OPT2,
          hInstance, nil);
        hwndStatic2 := CreateWindowEx(0, 'STATIC', '', WS_VISIBLE or WS_CHILD,
          25, 130, 100, 18, hWnd, IDC_STATIC1, hInstance, nil);

        {Standards}
        SetWindowText(hwndStatic1, 'Unchecked');
        SendMessage(hwndOpt1, BM_SETCHECK, BST_CHECKED, 0);
        buffer := 'Radiobutton1';
        SendMessage(hwndStatic2, WM_SETTEXT, 0, Integer(@buffer));
      end;
    WM_DESTROY:
      PostQuitMessage(0);
    WM_COMMAND:
      begin
        if hiword(wParam) = BN_CLICKED then
          case LoWord(wParam) of
            IDC_CHKBOX:
            begin
              bCBFlag := (SendMessage(hwndChkBox,BM_GETCHECK,0,0) = BST_CHECKED);
              SendMessage(hwndChkBox,BM_SETCHECK,CheckFlags[not(bCBFlag)],0);
              SetWindowText(hwndStatic1,@TextFlags[not(bCBFlag)][1]);
            end;
            IDC_OPT1:
            begin
              buffer := 'Radiobutton1';
              SendMessage(hwndStatic2, WM_SETTEXT, 0, Integer(@buffer));
            end;
            IDC_OPT2:
            begin
              buffer := 'Radiobutton2';
              SendMessage(hwndStatic2, WM_SETTEXT, 0, Integer(@buffer));
            end;
          end;
      end
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
  CreateWindowEx(WS_EX_CLIENTEDGE, ClassName, AppName, WS_CAPTION or WS_VISIBLE
    or WS_SYSMENU, CW_USEDEFAULT, CW_USEDEFAULT, WindowWidth, WindowHeight, 0,
    0, hInstance, nil);

  while GetMessage(msg,0,0,0) do
  begin
    TranslateMessage(msg);
    DispatchMessage(msg);
  end;
  ExitCode := msg.wParam;
end.