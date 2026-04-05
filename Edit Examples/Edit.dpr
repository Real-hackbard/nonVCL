program Edit;

{$R resource.res}

uses
  Windows,
  Messages;

const
  ClassName = 'WndClass';
  AppName = 'Edit';
  WindowWidth = 425;
  WindowHeight = 200;

const
  IDC_EDIT1 = 1;
  IDC_EDIT2 = 2;
  IDC_BUTTON1 = 3;
  IDC_LABEL1 = 4;
  iDC_LABEL2 = 5;
  IDC_LABEL3 = 6;
  IDC_BUTTON2 = 7;
  IDC_EDIT3 = 8;
  IDC_EDIT4 = 9;
  IDC_BUTTON3 = 10;

var
  hwndEdit1: DWORD;
  hwndEdit2: DWORD;
  hwndlabel2: DWORD;
  hwndLabel3: DWORD;
  hwndLabel1: DWORD;
  hwndButton1: DWORD;
  hwndButton2: DWORD;
  hwndButton3: DWORD;
  hwndEdit3: DWORD;
  hwndEdit4: DWORD;

  SelStart, SelEnd: Integer;

procedure CopyText(hwndEdit1, hwndEdit2, hwndLabel: DWORD);
var
  buffer: array[0..1024] of Char;
  Textlen: Integer;
begin
  {@: Adress-Operator}
  SendMessage(hwndEdit1, WM_GETTEXT, 1024, Integer(@buffer));
  Textlen := SendMessage(hwndEdit1, EM_LINELENGTH, 0, 0);
  SendMessage(hwndEdit2, WM_SETTEXT, 0, Integer(@buffer));
  wvsprintf(buffer, 'Copied characters: %d', PChar(@TextLen));
  SendMessage(hwndLabel1, WM_SETTEXT, 0, Integer(@buffer));
end;

procedure SelText(hwndEdit1, hwndEdit2, hwndEdit3, hwndEdit4: DWORD);
var
  buffer: array[0..1024] of Char;
  Code: Integer;
begin
  SendMessage(hwndEdit3, WM_GETTEXT, 1024, Integer(@buffer));
  val(buffer, SelStart, code);
  SendMessage(hwndEdit4, WM_GETTEXT, 1024, Integer(@buffer));
  val(buffer, SelEnd, code);
  SendMessage(hwndEdit1, EM_SETSEL, SelStart, SelEnd);
end;

procedure CopySel(hwndEdit1, hwndEdit2: DWORD);
var
  buffer: array[0..1024] of Char;
  Textlen: Integer;
begin
  SendMessage(hwndEdit1, EM_GETSEL, wParam(@SelStart), lParam(@SelEnd));
  TextLen := SelEnd - SelStart;
  if TextLen = 0 then exit;

  wvsprintf(buffer, 'Copied characters: %d', PChar(@TextLen));
  SendMessage(hwndLabel1, WM_SETTEXT, 0, Integer(@buffer));

  SendMessage(hwndEdit1, WM_COPY, 0, 0);
  SendMessage(hwndEdit2, WM_PASTE, 0, 0);
end;

{Window function}
function WndProc(hWnd: HWND; uMsg: UINT; wParam: wParam; lParam: LParam):
  lresult; stdcall;
var
  x, y : integer;   //Window position variables
begin
  Result := 0;
  case uMsg of
    WM_CREATE:
      begin
        {Center window}
        x := GetSystemMetrics(SM_CXSCREEN);   //Screenhöhe & -width
        y := GetSystemMetrics(SM_CYSCREEN);

        {Fenster auf neue Positionverschieben}
        MoveWindow(hWnd, (x div 2) - (WindowWidth div 2),
          (y div 2) - (WindowHeight div 2),
          WindowWidth, WindowHeight, true);

        {Create edit fields}
        hwndEdit1 := CreateWindowEx(WS_EX_CLIENTEDGE, 'EDIT', 'Edit1', WS_VISIBLE or
          WS_CHILD or ES_NOHIDESEL, 10, 20, 400, 20, hWnd, IDC_EDIT1, hInstance, nil);
        hwndEdit2 := CreateWindowEx(WS_EX_CLIENTEDGE, 'EDIT', '', WS_VISIBLE or
          WS_CHILD, 10, 55, 400, 20, hWnd, IDC_EDIT2, hInstance, nil);
        hwndEdit3 := CreateWindowEx(WS_EX_CLIENTEDGE, 'EDIT', '', WS_VISIBLE or
          WS_CHILD, 168, 100, 20, 19, hWnd, IDC_EDIT3, hInstance, nil);
        hwndEdit4 := CreateWindowEx(WS_EX_CLIENTEDGE, 'EDIT', '', WS_VISIBLE or
          WS_CHILD, 222, 100, 20, 19, hWnd, IDC_EDIT4, hInstance, nil);

        {Create edit fields}
        hwndLabel1 := CreateWindowEx(0, 'STATIC', 'Copied characters: ',
          WS_VISIBLE or WS_CHILD, 10, 80, 275, 20, hWnd, IDC_LABEL1, hInstance,
          nil);
        hwndLabel2 := CreateWindowEx(0, 'STATIC', 'Mark characters from: ',
          WS_VISIBLE or WS_CHILD, 10, 100, 157, 20,hWnd, IDC_LABEL2, hInstance,
          nil);
        hwndLabel3 := CreateWindowEx(0, 'STATIC', 'to: ', WS_VISIBLE or
          WS_CHILD, 190, 100, 30, 20, hWnd, IDC_LABEL3, hInstance, nil);

        {Buttons erstellen}
        hwndButton1 := CreateWindowEx(0, 'BUTTON', 'Copy text',
          WS_VISIBLE or WS_CHILD, 10, 130, 125, 25, hWnd, IDC_BUTTON1,
          hInstance, nil);
        hwndButton2 := CreateWindowEx(0, 'BUTTON', 'Mark',WS_VISIBLE or
          WS_CHILD, 145, 130, 125, 25, hWnd, IDC_BUTTON2, hInstance, nil);
        hwndButton3 := CreateWindowEx(0, 'BUTTON', 'Copy selection',
          WS_VISIBLE or WS_CHILD, 280, 130, 125, 25, hWnd, IDC_BUTTON3,
          hInstance, nil);
      end;
    WM_DESTROY: PostQuitMessage(0);
    WM_COMMAND:
      begin
        if hiword(wParam) = BN_CLICKED then
          case loword(wParam) of
            IDC_BUTTON1: CopyText(hwndEdit1, hwndEdit2, hwndLabel1);
            IDC_BUTTON2: SelText(hwndEdit1, hwndEdit2, hwndEdit3, hwndEdit4);
            IDC_BUTTON3: CopySel(hwndEdit1, hwndEdit2);
          end;
      end;
  else
    Result := DefWindowProc(hWnd, uMsg, wParam, lParam);
  end;
end;

var
  {Window class structure}
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
  wc.hIcon      := LoadIcon(hInstance, MAKEINTRESOURCE(100));
  wc.hCursor    := LoadCursor(0, IDC_ARROW);

  {Register windows}
  RegisterClassEx(wc);

  {Show window}
  CreateWindowEx(0, ClassName, AppName, WS_CAPTION or WS_VISIBLE or WS_SYSMENU,
    CW_USEDEFAULT, CW_USEDEFAULT, WindowWidth, WindowHeight, 0, 0, hInstance,
    nil);

  {Start message loop}
  while GetMessage(msg,0,0,0) do
  begin
    TranslateMessage(msg);
    DispatchMessage(msg);
  end;

  ExitCode := msg.wParam;
end.