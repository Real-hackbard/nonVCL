program Listbox;

{$R resource.res}

uses
  Windows,
  Messages;

const
  ClassName = 'WndClass';
  AppName = 'Listbox';
  WindowWidth = 395;
  WindowHeight = 310;

  IDC_LB = 1;
  IDC_LABELSELITEM = 2;
  IDC_EDITADDSTR = 3;
  IDC_BUTTONADDSTR = 4;
  IDC_BUTTONDELSTR = 5;
  IDC_LABELITEMSCOUNT = 6;
  IDC_EDITSELITEMS = 7;
  IDC_BUTTONCOPYITEMS = 8;
  IDC_BUTTONSELALL = 9;
  IDC_LABELSELCOUNT = 10;

var
  hwndListbox: DWORD;
  hwndLabelSelItem: DWORD;
  hwndEditAddStr: DWORD;
  hwndButtonAddStr: DWORD;
  hwndButtonDelStr: DWORD;
  hwndLabelItemsCount: DWORD;
  hwndEditSelItems: DWORD;
  hwndButtonCopyItems: DWORD;
  hwndButtonSelAll: DWORD;
  hwndLabelSelCount: DWORD;


procedure AddStr(hwndListbox, hwndEditAddStr, hwndLabelItemsCount: DWORD);
var
  buffer: array[0..255] of Char;
  i: Integer;
begin
  SendMessage(hwndEditAddStr, WM_GETTEXT, 256, Integer(@buffer));
  SendMessage(hwndListbox, LB_ADDSTRING, 0, Integer(@buffer));
  i := SendMessage(hwndListbox, LB_GETCOUNT, 0, 0);
  wvsprintf(buffer, 'Entries : %d', PChar(@i));
  SetWindowText(hwndLabelItemsCount, buffer);
  SetFocus(hwndEditAddStr);
end;

procedure DelStr(hwndListbox, hwndLabelSelItem, hwndLabelItemsCount: DWORD);
var
  buffer: array[0..255] of Char;
  i: Integer;
begin
  i := SendMessage(hwndListbox, LB_GETCOUNT, 0, 0);
  if i = 0 then exit;

  i := SendMessage(hwndListbox, LB_GETCURSEL, 0, 0);
  SendMessage(hwndListbox, LB_DELETESTRING, i, 0);
  SetWindowText(hwndLabelSelItem, '');
  i := SendMessage(hwndListbox, LB_GETCOUNT, 0, 0);
  wvsprintf(buffer, 'Entries : %d', PChar(@i));
  SetWindowText(hwndLabelItemsCount, buffer);
  SetFocus(hwndListbox);

  EnableWindow(hwndButtonDelStr,(i > 0));
  EnableWindow(hwndButtonCopyItems,(i > 0));
end;

procedure CopyItems(hwndListbox, hwndEditSelItems: DWORD);
var
  i: Integer;
  CountItems: Integer;
  SelItems : array of integer;
  buffer, buffer1: array[0..255] of Char;
begin
  buffer1 := '';
  CountItems := SendMessage(hwndListbox, LB_GETSELCOUNT, 0, 0);
  if CountItems = 0 then exit;

  SetLength(SelItems,CountItems);

  SendMessage(hwndListbox, LB_GETSELITEMS, CountItems, LPARAM(@SelItems[0]));
  for i := 0 to CountItems-1 do
  begin
    SendMessage(hwndListbox, LB_GETTEXT, SelItems[i], Integer(@buffer));
    lstrcat(buffer1, buffer);
    lstrcat(buffer1, '; ');
    SetWindowText(hwndEditSelItems, buffer1);
  end;

  SetLength(SelItems,0);
end;

procedure SelAll(hwndListbox: DWORD);
var
  CountItems, i: Integer;
  buffer: array[0..255] of Char;
begin
  CountItems := SendMessage(hwndListbox, LB_GETCOUNT, 0, 0);
  if CountItems = 0 then exit;

  for i := 0 to CountItems do
    SendMessage(hwndListbox, LB_SETSEL, Integer(true), i);
  wvsprintf(buffer, 'of which marked: %d', PChar(@CountItems));
  SetWindowText(hwndLabelSelCount, buffer);

  EnableWindow(hwndButtonDelStr,true);
  EnableWindow(hwndButtonCopyItems,true);
end;

function WndProc(hWnd: HWND; uMsg: UINT; wParam: wParam; lParam: LParam):
  lresult; stdcall;
var
  x, y : integer;
  i, j, Items, SelItems: Integer;
  buffer, buffer1: array[0..255] of Char;
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

        {Create list box}
        hwndListBox := CreateWindowEx(WS_EX_CLIENTEDGE, 'LISTBOX', nil, WS_CHILD
          or WS_VISIBLE or LBS_STANDARD or LBS_EXTENDEDSEL, 10, 10, 200, 230,
          hWnd, IDC_LB, hInstance, nil);
        {Fill list box}
        buffer := 'Peter';
        SendMessage(hwndListbox, LB_ADDSTRING, 0, Integer(@buffer));
        buffer := 'Sam';
        SendMessage(hwndListbox, LB_ADDSTRING, 0, Integer(@buffer));
        buffer := 'James';
        SendMessage(hwndListbox, LB_ADDSTRING, 0, Integer(@buffer));
        buffer := 'John';
        SendMessage(hwndListbox, LB_ADDSTRING, 0, Integer(@buffer));
        buffer := 'Michael';
        SendMessage(hwndListbox, LB_ADDSTRING, 0, Integer(@buffer));

        {Create label}
        hwndLabelSelItem := CreateWindowEx(0, 'STATIC', '', WS_VISIBLE or
          WS_CHILD or WS_BORDER, 220, 10, 150, 18, hWnd, IDC_LABELSELITEM,
          hInstance, nil);
        hwndLabelItemsCount := CreateWindowEx(0, 'STATIC', 'Entries:',
          WS_VISIBLE or WS_CHILD, 10, 250, 90, 18, hWnd, IDC_LABELITEMSCOUNT,
          hInstance, nil);
        hwndLabelSelCount := CreateWindowEx(0, 'STATIC', 'of which marked: 0',
          WS_VISIBLE or WS_CHILD, 95, 250, 120, 18, hWnd, IDC_LABELSELCOUNT,
          hInstance, nil);

        {Count entries}
        j := SendMessage(hwndListbox, LB_GETCOUNT, 0, 0);
        wvsprintf(buffer, 'Entries : %d', PChar(@j));
        SetWindowText(hwndLabelItemsCount, buffer);

        {Create edit}
        hwndEditAddStr := CreateWindowEx(WS_EX_CLIENTEDGE, 'EDIT', '',
          WS_VISIBLE or WS_CHILD, 220, 35, 150, 20, hWnd, IDC_EDITADDSTR,
          hInstance, nil);
        hwndEditSelItems := CreateWindowEx(WS_EX_CLIENTEDGE, 'EDIT', '',
          WS_VISIBLE or WS_CHILD or ES_MULTILINE, 220, 130, 150, 75, hWnd,
          IDC_EDITSELITEMS, hInstance, nil);

        {Create button}
        hwndButtonAddStr := CreateWindowEx(0, 'BUTTON', 'Add', WS_VISIBLE
          or WS_CHILD or WS_DISABLED, 220, 65, 150, 25, hWnd, IDC_BUTTONADDSTR, hInstance,
          nil);
        hwndButtonDelStr := CreateWindowEx(0, 'BUTTON', 'Delete', WS_VISIBLE
          or WS_CHILD or WS_DISABLED, 220, 95, 150, 25, hWnd, IDC_BUTTONDELSTR, hInstance,
          nil);
        hwndButtonCopyItems := CreateWindowEx(0, 'BUTTON', 'Copy selection',
          WS_VISIBLE or WS_CHILD or WS_DISABLED, 220, 215, 150, 25, hWnd, IDC_BUTTONCOPYITEMS,
          hInstance, nil);
        hwndButtonSelAll := CreateWindowEx(0, 'BUTTON', 'select everything',
          WS_VISIBLE or WS_CHILD, 220, 245, 150, 25, hWnd, IDC_BUTTONSELALL,
          hInstance, nil);
      end;
    WM_DESTROY:
      begin
        PostQuitMessage(0);
      end;
    WM_COMMAND:
      case hiword(wParam) of
        BN_CLICKED:
          case loword(wParam) of
            IDC_BUTTONADDSTR:
              AddStr(hwndListbox, hwndEditAddStr, hwndLabelItemsCount);
            IDC_BUTTONDELSTR:
              DelStr(hwndListbox, hwndLabelSelItem, hwndLabelItemsCount);
            IDC_BUTTONCOPYITEMS: CopyItems(hwndListbox, hwndEditSelItems);
            IDC_BUTTONSELALL: SelAll(hwndlistbox);
          end;
        LBN_SELCHANGE:
          case LoWord(wParam) of
            IDC_LB:
              begin
                buffer1 := '';
                SelItems := 0;
                Items := SendMessage(hwndListbox, LB_GETCOUNT, 0, 0);
                for i := 0 to Items do
                  if SendMessage(hwndListbox, LB_GETSEL, i, 0) > 0 then
                    begin
                      Inc(SelItems);
                      wvsprintf(buffer1, 'of which marked: %d', PChar(@SelItems));
                      lstrcpy(buffer, buffer1);
                    end;

                {Activate buttons}
                EnableWindow(hwndButtonDelStr,(SelItems > 0));
                EnableWindow(hwndButtonCopyItems,(SelItems > 0));

                SetWindowText(hwndLabelSelCount, buffer1);
                i := SendMessage(hwndListbox, LB_GETCURSEL, 0, 0);
                SendMessage(hwndListbox, LB_GETTEXT, i, Integer(@buffer));
                SetWindowText(hwndLabelSelItem, buffer);
              end;
          end;
        EN_CHANGE:
          if loword(wParam) = IDC_EDITADDSTR then
            begin
              ZeroMemory  (@buffer,sizeof(buffer));
              EnableWindow(hwndButtonAddStr,GetWindowText(hwndEditAddStr,buffer,256) > 0);
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