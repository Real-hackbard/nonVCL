program Combobox;

{$R resource.res}

uses
  Windows,
  Messages;

const
  ClassName = 'WndClass';
  AppName = 'ComboBox';
  WindowWidth = 470;
  WindowHeight = 210;

  IDC_CB = 1;
  IDC_SELECTEDITEM = 2;
  IDC_TEXT = 3;
  IDC_ADD = 4;
  IDC_EDIT = 5;
  IDC_DEL = 6;
  IDC_DELALL = 7;

var
  hCB: DWORD;
  hText: DWORD;
  hSelItem: DWORD;
  hAdd: DWORD;
  hEdit: DWORD;
  hDel: DWORD;
  hItemCount: DWORD;
  hDelAll: DWORD;


function WndProc(hWnd: HWND; uMsg: UINT; wParam: wParam; lParam: LParam):
  lresult; stdcall;
var
  x, y : integer;
  buffer: array[0..255] of Char;
  i: Integer;
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

        hCB := CreateWindowEx(0, 'COMBOBOX', '', WS_CHILD or WS_VISIBLE or
          CBS_AUTOHSCROLL or CBS_DROPDOWN or CBS_SORT or WS_VSCROLL, 10, 10, 150,
          150, hWnd, IDC_CB, hInstance, nil);
        buffer := 'Peter';
        SendMessage(hCB, CB_ADDSTRING, 0, Integer(@buffer));
        buffer := 'Sam';
        SendMessage(hCB, CB_ADDSTRING, 0, Integer(@buffer));
        buffer := 'John';
        SendMessage(hCB, CB_ADDSTRING, 0, Integer(@buffer));
        buffer := 'James';
        SendMessage(hCB, CB_ADDSTRING, 0, Integer(@buffer));
        buffer := 'Fritz';
        SendMessage(hCB, CB_ADDSTRING, 0, Integer(@buffer));
        buffer := 'Thomas';
        SendMessage(hCB, CB_ADDSTRING, 0, Integer(@buffer));
        buffer := 'Donald';
        SendMessage(hCB, CB_ADDSTRING, 0, Integer(@buffer));
        buffer := 'Andrea';
        SendMessage(hCB, CB_ADDSTRING, 0, Integer(@buffer));

        hText := CreateWindowEx(0, 'STATIC', 'selected entry:', WS_CHILD or
          WS_VISIBLE, 170, 10, 125, 20, hWnd, 0, hInstance, nil);
        hSelItem := CreateWindowEx(0, 'STATIC', '', WS_CHILD or WS_VISIBLE or
          SS_SUNKEN, 300, 10, 150, 20, hWnd, 0, hInstance, nil);
        hAdd := CreateWindowEx(0, 'BUTTON', 'Add entry', WS_CHILD or
          WS_VISIBLE or WS_DISABLED, 300, 50, 150, 25, hWnd, IDC_ADD, hInstance, nil);
        hEdit := CreateWindowEx(WS_EX_CLIENTEDGE, 'EDIT', '', WS_CHILD or
          WS_VISIBLE or ES_AUTOHSCROLL, 170, 52, 125, 20, hWnd, IDC_EDIT,
          hInstance, nil);
        hDel := CreateWindowEx(0, 'BUTTON', 'Delete selected entry',
          WS_CHILD or WS_VISIBLE or WS_DISABLED, 170, 90, 280, 25, hWnd, IDC_DEL, hInstance,
          nil);
        hDelAll := CreateWindowEx(0, 'BUTTON', 'delete all entries',
          WS_CHILD or WS_VISIBLE, 170, 125, 280, 25, hWnd, IDC_DELALL,
          hInstance, nil);
        hItemCount := CreateWindowEx(0, 'STATIC', '', WS_CHILD or WS_VISIBLE or
          SS_SUNKEN, 10, 160, 440, 20, hWnd, 0, hInstance, nil);

        i := SendMessage(hCB, CB_GETCOUNT, 0, 0);
        wvsprintf(buffer, '%d', PChar(@i));
        lstrcat(buffer, ' Entries in the combobox');
        SendMessage(hItemCount, WM_SETTEXT, 0, Integer(@buffer));
      end;
    WM_DESTROY:
      begin
        PostQuitMessage(0);
      end;
    WM_COMMAND:
      case hiword(wParam) of
        CBN_SELCHANGE:
          case LoWord(wParam) of
            IDC_CB:
            begin
              i := SendMessage(hCB, CB_GETCURSEL, i, 0);
              if(i <> CB_ERR) then
                begin
                  Sendmessage (hCB, CB_GETLBTEXT, i, Integer(@buffer));
                  SendMessage (hSelItem, WM_SETTEXT, 0, Integer(@buffer));
                  EnableWindow(hDel,true);
                end;
            end;
          end;
        BN_CLICKED:
          case LoWord(wParam) of
            IDC_ADD:
            begin
              SendMessage(hEdit, WM_GETTEXT, 256, Integer(@buffer));
              if(buffer[0] = #0) then exit;

              SendMessage(hCB, CB_ADDSTRING, 0, Integer(@buffer));
              ZeroMemory(@buffer, sizeof(buffer));
              SendMessage(hEdit, WM_SETTEXT, 0, Integer(@buffer));
              i := SendMessage(hCB, CB_GETCOUNT, 0, 0);
              wvsprintf(buffer, '%d', PChar(@i));
              lstrcat(buffer, ' Entries in the combobox');
              SendMessage(hItemCount, WM_SETTEXT, 0, Integer(@buffer));
            end;
            IDC_DEL:
            begin
              i := SendMessage(hCB, CB_GETCURSEL, i, 0);
              if(i = CB_ERR) then exit;

              Sendmessage(hCB, CB_DELETESTRING, i, 0);
              i := SendMessage(hCB, CB_GETCOUNT, 0, 0);
              wvsprintf(buffer, '%d', PChar(@i));
              lstrcat(buffer, ' Entries in the combobox');
              SendMessage(hItemCount, WM_SETTEXT, 0, Integer(@buffer));
              ZeroMemory(@buffer, sizeof(buffer));
              SendMessage(hSelItem, WM_SETTEXT, 0, Integer(@buffer));
            end;
            IDC_DELALL:
            begin
              SendMessage(hCB, CB_RESETCONTENT, 0, 0);
              i := SendMessage(hCB, CB_GETCOUNT, 0, 0);
              wvsprintf(buffer, '%d', PChar(@i));
              lstrcat(buffer, ' Entries in the combobox');
              SendMessage(hItemCount, WM_SETTEXT, 0, Integer(@buffer));
              EnableWindow(hDel,false);
            end;
          end;
        EN_CHANGE:
          if loword(wParam) = IDC_EDIT then
            begin
              SendMessage(hEdit, WM_GETTEXT, 256, Integer(@buffer));
              EnableWindow(hAdd,buffer[0] <> #0);
            end;
      end;
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
  wc.hIcon      := LoadIcon(hInstance, MAKEINTRESOURCE(100));
  wc.hCursor    := LoadCursor(0, IDC_ARROW);

  RegisterClassEx(wc);
  CreateWindowEx(0, ClassName, AppName, WS_CAPTION or WS_VISIBLE or WS_SYSMENU,
    CW_USEDEFAULT, CW_USEDEFAULT, WindowWidth, WindowHeight, 0, 0, hInstance,
    nil);

  while GetMessage(msg,0,0,0) do
  begin
    TranslateMessage(msg);
    DispatchMessage(msg);
  end;
  ExitCode := msg.wParam;
end.