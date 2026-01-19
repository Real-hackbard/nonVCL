program Toolbar;

//
// Note, this demo creates a Registry key to save your button settings.
// You can remove "HKCU\Software\Win32-API-Tutorials\Toolbar-Demo"
// manually, or you can use my VBScript to remove it.
//

{$DEFINE CREATETOOLBARWITHICONS}
{.$DEFINE USEMASKBITMAP}
{.$DEFINE USECREATEWINDOWEX}


{$R resource.res}

uses
  Windows,
  Messages,
  CommCtrl,
  ShellAPI,
  MSysUtils in 'MSysUtils.pas',
  CommCtrl_Fragment in 'CommCtrl_Fragment.pas';


//
// "WndProc"
//
const
  wWidth         = 500;
  wHeight        = 150;
  szCustomKey    = 'Software\Win32-API-Tutorials\Toolbar-Demo';
  szCustomVal    = 'ToolbarSettings';
  IDC_BUTTON1    = 1;
  IDC_BUTTON2    = 2;
  IDC_BUTTON3    = 3;
  IDC_TOOLBAR    = 4;
  IDM_DEACTIVATE = 5;
  IDM_CUSTOMIZE  = 6;
var
  TB_Text        : string = 'Button 1'#0'Button 2'#0'Button 3'#0#0;
  hToolbar       : HWND;
  hPopup         : HMENU;
  fActivate      : boolean = true;
  tbButtons      : array[0..3]of TTBButton =
    ((iBitmap:0;
      idCommand:IDC_BUTTON1;
      fsState:TBSTATE_ENABLED;
      fsStyle:BTNS_BUTTON or BTNS_SHOWTEXT or BTNS_AUTOSIZE;
      dwData:0;
      iString:0;),
     (iBitmap:0;
      idCommand:0;
      fsState:TBSTATE_ENABLED;
      fsStyle:BTNS_SEP;
      dwData:0;
      iString:-1;),
     (iBitmap:1;
      idCommand:IDC_BUTTON2;
      fsState:TBSTATE_ENABLED;
      fsStyle:BTNS_BUTTON or BTNS_SHOWTEXT or BTNS_AUTOSIZE;
      dwData:0;
      iString:1;),
     (iBitmap:2;
      idCommand:IDC_BUTTON3;
      fsState:TBSTATE_ENABLED;
      fsStyle:BTNS_DROPDOWN or BTNS_SHOWTEXT or BTNS_AUTOSIZE;
      dwData:0;
      iString:2;));

      
procedure ToolBarUsingBitmap(wnd: HWND);
var
  hBitmap : THandle;
{$IFDEF USEMASKBITMAP}
  cm      : array[0..3]of TColorMap;
{$ENDIF}
{$IFDEF USECREATEWINDOWEX}
  aBmp    : TTBAddBitmap;
{$ENDIF}
begin
{$IFDEF USEMASKBITMAP}
  cm[0].cFrom := $000000ff; // Rot
  cm[0].cTo   := GetSysColor(COLOR_BTNFACE);
  cm[1].cFrom := $00ff0000; // Blau
  cm[1].cTo   := GetSysColor(COLOR_BTNFACE);
  cm[2].cFrom := $00ff00ff; // Lila
  cm[2].cTo   := GetSysColor(COLOR_BTNFACE);
  cm[3].cFrom := $00000000; // Schwarz (= Text)
  cm[3].cTo   := GetSysColor(COLOR_BTNTEXT);
  hBitmap     := CreateMappedBitmap(hInstance,200,0,@cm[0],length(cm));
{$ELSE}
  hBitmap     := CreateMappedBitmap(hInstance,100,0,nil,0);
{$ENDIF}

{$IFDEF USECREATEWINDOWEX}
  hToolBar := CreateWindowEx(0, TOOLBARCLASSNAME, nil, WS_CHILD or
    WS_VISIBLE or CCS_ADJUSTABLE or CCS_NODIVIDER or TBSTYLE_FLAT or
    TBSTYLE_ALTDRAG, 0, 0, 0, 0, wnd, IDC_TOOLBAR, hInstance, nil);

  SendMessage(hToolBar, TB_BUTTONSTRUCTSIZE, sizeof(TTBBUTTON), 0);
  SendMessage(hToolBar, TB_ADDBUTTONS, length(tbButtons), LPARAM(@tbButtons));
    
  aBmp.hInst := 0;
  aBmp.nID   := hBitmap;
  SendMessage(hToolBar, TB_ADDBITMAP, 3, LPARAM(@aBmp));
{$ELSE}
  hToolbar := CreateToolbarEx(wnd, WS_CHILD or WS_VISIBLE or CCS_ADJUSTABLE or
    CCS_NODIVIDER or TBSTYLE_FLAT or TBSTYLE_ALTDRAG, IDC_TOOLBAR, 3, 0,
    hBitmap, @tbButtons, length(tbButtons), 0, 0, 16, 15, sizeof(TTBBUTTON));
{$ENDIF}

  // set extended style
  SendMessage(hToolBar, TB_SETEXTENDEDSTYLE, 0, TBSTYLE_EX_DRAWDDARROWS or
    TBSTYLE_EX_MIXEDBUTTONS);

  // set button text
  SendMessage(hToolBar, TB_ADDSTRING, 0, LPARAM(@TB_Text[1]));
end;

procedure ToolBarUsingIcons(wnd: HWND);

  function GetIconIndex(const Extension: string): integer;
  var
    fi     : TSHFileInfo;
  begin
    ZeroMemory(@fi, sizeof(fi));
    SHGetFileInfo(pchar(Extension), FILE_ATTRIBUTE_NORMAL, fi, sizeof(fi),
      SHGFI_ICON or SHGFI_SYSICONINDEX or SHGFI_SMALLICON or
      SHGFI_USEFILEATTRIBUTES);

    Result := fi.iIcon;
  end;

var
  hTBImgList : HIMAGELIST;
  fi         : TSHFileInfo;
begin
  // create toolbar using CreateWindowEx
  hToolBar := CreateWindowEx(0, TOOLBARCLASSNAME, nil, WS_CHILD or
    WS_VISIBLE or CCS_ADJUSTABLE or CCS_NODIVIDER or TBSTYLE_FLAT or
    TBSTYLE_ALTDRAG, 0, 0, 0, 0, wnd, IDC_TOOLBAR, hInstance, nil);

  // load icons
  ZeroMemory(@fi,sizeof(TSHFileInfo));
  hTbImgList  := HIMAGELIST(SHGetFileInfo('', 0, fi, sizeof(fi),
    SHGFI_SYSICONINDEX or SHGFI_ICON));

  // patch buttons
  tbButtons[0].iBitmap := GetIconIndex('.dll');
  tbButtons[2].iBitmap := GetIconIndex('.bat');
  tbButtons[3].iBitmap := GetIconIndex('.txt');

  // set buttons
  SendMessage(hToolBar, TB_BUTTONSTRUCTSIZE, sizeof(TTBBUTTON), 0);
  SendMessage(hToolBar, TB_ADDBUTTONS, length(tbButtons),
    LPARAM(@tbButtons));

  // set imagelist
  SendMessage(hToolbar, TB_SETIMAGELIST, 0, hTBImgList);

  // set extended style
  SendMessage(hToolBar, TB_SETEXTENDEDSTYLE, 0, TBSTYLE_EX_DRAWDDARROWS or
    TBSTYLE_EX_MIXEDBUTTONS);

  // set button text
  SendMessage(hToolBar, TB_ADDSTRING, 0, LPARAM(@TB_Text[1]));
end;

procedure SaveOrLoadToolbarSettings(SaveSettings: boolean = false);
var
  sp : TTBSaveParams;
begin
  sp.hkr          := HKEY_CURRENT_USER;
  sp.pszSubKey    := szCustomKey;
  sp.pszValueName := szCustomVal;
  SendMessage(hToolbar, TB_SAVERESTORE, WPARAM(SaveSettings), LPARAM(@sp));
end;


function WndProc(wnd: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM): LRESULT;
  stdcall;
const
  MenuFlag   : array[boolean]of cardinal = (0,MF_CHECKED);
var
  x, y       : integer;
  rect       : TRect;
  pt         : TPOINT;
  nItem,
  i          : integer;
begin
  Result := 0;
  case uMsg of
    WM_CREATE:
      begin
        // Center window
        x := GetSystemMetrics(SM_CXSCREEN);
        y := GetSystemMetrics(SM_CYSCREEN);
        MoveWindow(wnd,(x div 2) - (wWidth div 2),(y div 2) - (wHeight div 2),
          wWidth,wHeight,true);

        // Create toolbar
{$IFDEF CREATETOOLBARWITHICONS}
        ToolBarUsingIcons(wnd);
{$ELSE}
        ToolBarUsingBitmap(wnd);
{$ENDIF}

        // Settings loaded
        SaveOrLoadToolbarSettings;
      end;
    WM_DESTROY:
      begin
        // Save settings
        SaveOrLoadToolbarSettings(true);
        PostQuitMessage(0);
      end;
    WM_SIZE:
      // Adjust toolbar to window size
      MoveWindow(hToolbar, 0, 0, LOWORD(lp), HIWORD(lp), true);
    WM_GETMINMAXINFO:
      begin
        PMinMaxInfo(lp)^.ptMinTrackSize.X := wWidth;
        PMinMaxInfo(lp)^.ptMinTrackSize.Y := wHeight;
      end;
    WM_COMMAND:
      if(HIWORD(wp) = BN_CLICKED) then
        case LOWORD(wp) of
          IDC_BUTTON1:
            SendMessage(wnd, WM_CLOSE, 0, 0);
          IDC_BUTTON2,
          IDC_BUTTON3:
            MessageBox(wnd, 'Button clicked', 'Info', MB_ICONINFORMATION);
          IDM_DEACTIVATE:
            begin
              fActivate := not(fActivate);
              SendMessage(hToolBar, TB_ENABLEBUTTON, IDC_BUTTON2,
                LPARAM(fActivate));
            end;
          IDM_CUSTOMIZE:
            SendMessage(hToolbar,TB_CUSTOMIZE,0,0);
        end;
    WM_NOTIFY:
      case PNMToolBar(lp)^.hdr.code of
        // 3. Button with dropdown menu
        TBN_DROPDOWN:
          begin
            SendMessage(hToolbar, TB_GETRECT, PNMToolBar(lp)^.iItem,
              LPARAM(@Rect));

            pt.x   := Rect.Left;
            pt.y   := Rect.Bottom;
            ClientToScreen(wnd,pt);
            hPopup := CreatePopupMenu;
            AppendMenu(hPopup, MF_STRING or MenuFlag[fActivate=false],
              IDM_DEACTIVATE, 'Disable toolbar button 2');
            AppendMenu(hPopup, MF_STRING,IDM_CUSTOMIZE, 'Adjust ...');

            TrackPopupMenu(hPopup, TPM_LEFTALIGN or TPM_LEFTBUTTON,
              pt.x, pt.y, 0, wnd, nil);
            DestroyMenu(hPopup);
          end;

        //
        // Toolbar-Customization
        //
        TBN_CUSTHELP:
          MessageBox(wnd, 'Hier könnte Ihre Hilfe erscheinen!',
            'Toolbar-Demo', MB_OK or MB_ICONINFORMATION);

        // Which buttons can be added or removed?
        TBN_QUERYINSERT,
        TBN_QUERYDELETE:
          begin
            nItem  := PNMToolbar(lp)^.iItem;
            Result := LRESULT(nItem < length(tbButtons));
          end;
        TBN_GETBUTTONINFO:
          begin
            nItem := PNMToolBar(lp)^.iItem;
            if(nItem < length(tbButtons)) then
            begin
              PNMToolBar(lp)^.tbButton := tbButtons[nItem];
            end;
            Result := LRESULT(not(nItem=length(tbButtons)));
          end;
        TBN_TOOLBARCHANGE:
          SendMessage(PNMToolbar(lp)^.hdr.hwndFrom,TB_AUTOSIZE,0,0);
        TBN_RESET:
          begin
            nItem :=
              SendMessage(PNMToolbar(lp)^.hdr.hwndFrom, TB_BUTTONCOUNT, 0, 0);
            for i := nItem - 1 downto 0 do
              SendMessage(PNMToolbar(lp)^.hdr.hwndFrom, TB_DELETEBUTTON, i, 0);

            SendMessage(PNMToolbar(lp)^.hdr.hwndFrom, TB_ADDBUTTONS,
              length(tbButtons), LPARAM(@tbButtons));
          end;
      end;
    else
      Result := DefWindowProc(wnd,uMsg,wp,lp);
  end;
end;


//
// WinMain
//
const
  szClassName = 'TBWndClass';
  szAppName   = 'Toolbar Demo';
var
  wc          : TWndClassEx =
    (cbSize:SizeOf(TWndClassEx);
     Style:CS_HREDRAW or CS_VREDRAW;
     lpfnWndProc:@WndProc;
     cbClsExtra:0;
     cbWndExtra:0;
     lpszMenuName:nil;
     lpszClassName:szClassname;
     hIconSm:0;);
  msg         : TMsg;
  aWnd        : HWND;
begin
  InitCommonControls;

  // Register window class
  wc.hInstance     := hInstance;
  wc.hIcon         := LoadIcon(0,IDI_APPLICATION);
  wc.hCursor       := LoadCursor(0,IDC_ARROW);
  wc.hbrBackground := GetSysColorBrush(COLOR_3DFACE);
  if(RegisterClassEx(wc) = 0) then exit;

  // Create window
  aWnd := CreateWindowEx(0, szClassname, szAppname, WS_VISIBLE or WS_CAPTION or
    WS_SYSMENU or WS_MINIMIZEBOX or WS_MAXIMIZEBOX or WS_SIZEBOX,
    integer(CW_USEDEFAULT), integer(CW_USEDEFAULT), wWidth, wHeight, 0, 0,
    hInstance, nil);
  if(aWnd = 0) then exit;
  ShowWindow(aWnd,SW_SHOW);
  UpdateWindow(aWnd);

  // Message loop
  while(GetMessage(msg,0,0,0)) do
  begin
    TranslateMessage(msg);
    DispatchMessage(msg);
  end;

  ExitCode := msg.wParam;
end.
