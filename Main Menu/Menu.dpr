program Menu;

{.$DEFINE LOADMENU}

{$R resource.res}
{$R menuhelp.res}
{$IFDEF LOADMENU} {$R Menu.res} {$ENDIF}

uses
  Windows,
  Messages,
  CommCtrl;

const
  ClassName    = 'WndClass';
  AppName      = 'Main Menü';
  WindowWidth  = 300;
  WindowHeight = 200;

  IDM_ITEM1    = 1;
  IDM_ITEM2    = 2;
  IDM_ITEM3    = 3;
  IDM_ITEM4    = 4;
  IDM_ITEM5    = 5;
  IDC_ENABLE   = 6;
  IDC_DISABLE  = 7;
  IDM_CLOSE    = 8;

  IDC_STATUS   = 1;
var
  hMainMenu,
  hSubMenu     : HMENU;
  hStatus,
  hEnable,
  hDisable     : HWND;

const
  MnuTextArray : array[boolean]of string =
    ('Item 1 activate','Item 1 deaktivate');
  MnuFlagArray : array[boolean]of cardinal =
    (IDC_ENABLE,IDC_DISABLE);
var
  isEnabled    : boolean = false;
  p            : TPoint;
  dummy        : uint = 0;


function WndProc(wnd: HWND; uMsg: UINT; wp: wParam; lp: LParam):
  LRESULT; stdcall;
var
  buffer : array[0..255] of Char;
begin
  Result := 0;

  case uMsg of
    WM_CREATE:
      begin
        // Create menu
{$IFNDEF LOADMENU}
        hMainMenu := CreateMenu;

        // Fill menus with entries
        hSubMenu := CreatePopupMenu;
        AppendMenu(hMainMenu,MF_STRING or MF_POPUP,hSubMenu,'Menü&1');
        AppendMenu(hSubMenu,MF_STRING,IDM_ITEM1,'Item&1');
        AppendMenu(hSubMenu,MF_STRING,IDM_ITEM2,'Item&2');
        AppendMenu(hSubMenu,MF_SEPARATOR,0,nil);
        AppendMenu(hSubMenu,MF_STRING,IDM_ITEM3,'Item&3');

        hSubMenu := CreatePopupMenu;
        AppendMenu(hMainMenu,MF_STRING or MF_POPUP,hSubMenu,'Menü&2');
        AppendMenu(hSubMenu,MF_STRING,IDM_ITEM4,'Item&4');
        AppendMenu(hSubMenu,MF_STRING,IDM_ITEM5,'Item&5');

        // Assign menu to window
        SetMenu(wnd, hMainMenu);
{$ELSE}
        hMainMenu := GetMenu(wnd);
{$ENDIF}

        // Buttons, & Create status line
        hDisable := CreateWindowEx(WS_EX_CLIENTEDGE, 'BUTTON',
          'Item1 deaktivate', WS_VISIBLE or WS_CHILD, 10, 10, 150, 25,
          wnd, IDC_DISABLE, hInstance, nil);
        hEnable  := CreateWindowEx(WS_EX_CLIENTEDGE, 'BUTTON',
          'Item1 aktivate', WS_VISIBLE or WS_CHILD, 10, 40, 150, 25,
          wnd, IDC_ENABLE, hInstance, nil);
        hStatus  := CreateWindowEx(0, STATUSCLASSNAME, nil, WS_CHILD or
          WS_VISIBLE, 0, 0, 0, 0, wnd, IDC_STATUS, hInstance, nil);
      end;
    WM_DESTROY:
      begin
{$IFNDEF LOADMENU}
        DestroyMenu(hMainMenu);
{$ENDIF}
        PostQuitMessage(0);
      end;
    WM_SIZE:
      MoveWindow(hStatus,LOWORD(lp),HIWORD(lp),0,0,true);
    WM_COMMAND:
      // Menu entries are treated like button clicks
      if HIWORD(wp) = BN_CLICKED then
        case LOWORD(wp) of
          IDM_ITEM1,
          IDM_ITEM2,
          IDM_ITEM3,
          IDM_ITEM4,
          IDM_ITEM5:
            begin
              ZeroMemory(@buffer,sizeof(buffer));
              wvsprintf(buffer,'Item %d',pchar(@LOWORD(wp)));
              MessageBox(wnd,buffer,'Selected menu item',MB_ICONINFORMATION);
            end;
          IDM_CLOSE:
            SendMessage(wnd,WM_CLOSE,0,0);
          IDC_ENABLE:
            EnableMenuItem(hMainMenu,IDM_ITEM1,MF_BYCOMMAND or MF_ENABLED);
          IDC_DISABLE:
            EnableMenuItem(hMainMenu,IDM_ITEM1,MF_BYCOMMAND or MF_GRAYED);
        end;
    WM_MENUSELECT:
      begin
        if(bool(HIWORD(wp) and MF_POPUP)) or
          (bool(HIWORD(wp) and MF_SEPARATOR)) or
          (HIWORD(wp) = $FFFF) then
        SendMessage(hStatus,SB_SIMPLE,0,0)
          else MenuHelp(uMsg,wp,lp,HMENU(lp),hInstance,hStatus,@dummy);
      end;
    WM_RBUTTONUP:
      begin
        isEnabled :=
          GetMenuState(hMainMenu, IDM_ITEM1, MF_BYCOMMAND) <> MF_GRAYED;
        
        // Generate popup menu
        hSubMenu := CreatePopupMenu;
        AppendMenu(hSubMenu,MF_STRING,MnuFlagArray[isEnabled],
          @MnuTextArray[isEnabled][1]);
        AppendMenu(hSubMenu,MF_SEPARATOR,0,nil);
        AppendMenu(hSubMenu,MF_STRING,IDM_CLOSE,'End program');

        // Show popup menu, & then share
        GetCursorPos(p);
        SetForegroundWindow(wnd);
        TrackPopupMenu(hSubMenu,TPM_RIGHTALIGN,p.X,p.Y,0,wnd,nil);

        DestroyMenu(hSubMenu);
      end;
  else
    Result := DefWindowProc(wnd,uMsg,wp,lp);
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
  icc: TInitCommonControlsEx = (
    dwSize:sizeof(TInitCommonControlsEx);
    dwICC:ICC_BAR_CLASSES;
  );

begin
  InitCommonControlsEx(icc);

  wc.hInstance  := hInstance;
  wc.hIcon      := LoadIcon(hInstance, MAKEINTRESOURCE(100));
  wc.hCursor    := LoadCursor(0, IDC_ARROW);
  RegisterClassEx(wc);

  CreateWindowEx(0,ClassName,AppName,WS_CAPTION or WS_VISIBLE or
    WS_OVERLAPPEDWINDOW,integer(CW_USEDEFAULT),integer(CW_USEDEFAULT),
    WindowWidth,WindowHeight,0,
{$IFDEF LOADMENU}
    LoadMenu(hInstance,MAKEINTRESOURCE(200)),
{$ELSE}
    0,
{$ENDIF}
    hInstance, nil);

  while GetMessage(msg,0,0,0) do
  begin
    TranslateMessage(msg);
    DispatchMessage(msg);
  end;
  ExitCode := msg.wParam;
end.
