program rebar2;

{.$DEFINE USEBMPICO}
{.$DEFINE PSDK}
{.$DEFINE LAYOUTSAVING}


uses
  Windows,
  Messages,
  CommCtrl,
  CommCtrl_Fragment in 'CommCtrl_Fragment.pas',
  MSysUtils in 'MSysUtils.pas';

{$R rebar.res}
//{$IFDEF USEBMPICO}
{$R bmp-ico.res}
//{$ENDIF}


const
  IDC_REBAR    = 2000;
  IDC_COMBOBOX = 2001;
  IDC_BUTTON   = 2002;
  IDC_TOOLBAR  = 2003;
  IDC_MAINICON =  200;
  IDC_BACKBMP  =  300;

  IDC_NEWBTN   = 1000;
  IDC_OPENBTN  = 1001;
  IDC_SAVEBTN  = 1002;

var
  tbButtons    : array[0..3]of TTBButton =
    ((iBitmap:STD_FILENEW;
      idCommand:IDC_NEWBTN;
      fsState:TBSTATE_ENABLED;
      fsStyle:BTNS_BUTTON or BTNS_SHOWTEXT;
      dwData:0;
      iString:0;),
     (iBitmap:0;
      idCommand:0;
      fsState:TBSTATE_ENABLED;
      fsStyle:BTNS_SEP;
      dwData:0;
      iString:-1;),
     (iBitmap:STD_FILEOPEN;
      idCommand:IDC_OPENBTN;
      fsState:TBSTATE_ENABLED;
      fsStyle:BTNS_BUTTON or BTNS_SHOWTEXT;
      dwData:0;
      iString:1;),
     (iBitmap:STD_FILESAVE;
      idCommand:IDC_SAVEBTN;
      fsState:TBSTATE_ENABLED;
      fsStyle:BTNS_BUTTON or BTNS_SHOWTEXT;
      dwData:0;
      iString:2;));
var
  szBtnText    : string = 'New'#0'Open'#0'Save'#0#0;


//
// Produce rebar
//
procedure BuildRebar(const hwndParent: HWND;
  var hRebar, hToolbar: HWND
  {$IFDEF USEBMPICO}; var hImgList: HIMAGELIST {$ENDIF});
var
  hwndRebar,
  hwndChild  : HWND;
{$IFDEF USEBMPICO}
  himlRebar  : HIMAGELIST;
  hIco       : HICON;
  rbi        : TRebarInfo;
{$ENDIF}
  i          : integer;
  szItem     : string;
  rc         : TRect;
  rbbi       : TRebarBandInfo;
  aBmp       : TTBAddBitmap;
  dwBtnSize  : dword;
  iIdeal     : integer;
begin
  hwndRebar := CreateWindowEx(WS_EX_TOOLWINDOW,REBARCLASSNAME,nil,
    WS_VISIBLE or WS_BORDER or WS_CHILD or WS_CLIPCHILDREN or
    WS_CLIPSIBLINGS or RBS_VARHEIGHT or RBS_BANDBORDERS or
    RBS_DBLCLKTOGGLE,0,0,0,0,hwndParent,IDC_REBAR,hInstance,nil);

  if(hwndRebar <> 0) then begin
    // Passing "hwndRebar" to VAR parameter "hRebar"
    hRebar  := hwndRebar;

{$IFDEF USEBMPICO}
    himlRebar  := ImageList_Create(32,32,ILC_COLORDDB or ILC_MASK,1,0);
    hIco       := LoadIcon(hInstance,MAKEINTRESOURCE(IDC_MAINICON));
    ImageList_AddIcon(himlRebar,hIco);

    ZeroMemory(@rbi,sizeof(rbi));
    rbi.cbSize := sizeof(TRebarInfo);
    rbi.fMask  := RBIM_IMAGELIST;
    rbi.himl   := himlRebar;
    SendMessage(hwndRebar,RB_SETBARINFO,0,LPARAM(@rbi));

    // Passing ImageList to VAR parameters
    hImgList   := himlRebar;
{$ENDIF}

    // Create ComboBox
    hwndChild := CreateWindowEx(0,'combobox',nil,WS_VISIBLE or WS_CHILD or
      WS_TABSTOP or WS_VSCROLL or WS_CLIPCHILDREN or WS_CLIPSIBLINGS or
      CBS_AUTOHSCROLL or CBS_DROPDOWN,0,0,100,200,hwndRebar,IDC_COMBOBOX,
      hInstance,nil);

    if(hwndChild <> 0) then begin
      // Assign default font
      SendMessage(hwndChild,WM_SETFONT,
        WPARAM(GetStockObject(DEFAULT_GUI_FONT)),MAKELPARAM(1,0));

      // Create entries
      for i := 1 to 100 do begin
        szItem := Format('Eintrag Nr. %d',[i]);
        SendMessage(hwndChild,CB_ADDSTRING,0,LPARAM(@szItem[1]));
      end;
      SendMessage(hwndChild,CB_SETCURSEL,0,0);

      // Determine the dimensions of the combo box
      GetWindowRect(hwndChild,rc);

      // Insert combobox as "band" into the rebar
      ZeroMemory(@rbbi,sizeof(rbbi));
      rbbi.cbSize     := sizeof(TRebarBandInfo);
      rbbi.fMask      := RBBIM_SIZE or RBBIM_CHILD or RBBIM_CHILDSIZE or
        RBBIM_ID or RBBIM_STYLE or RBBIM_TEXT
{$IFDEF USEBMPICO}
        or RBBIM_BACKGROUND
{$ENDIF}
        ;
      rbbi.cxMinChild := rc.Right - rc.Left;
      rbbi.cyMinChild := rc.Bottom - rc.Top;
      rbbi.cx         := 100;
      rbbi.fStyle     := RBBS_CHILDEDGE or RBBS_GRIPPERALWAYS
{$IFDEF USEBMPICO}
        or RBBS_FIXEDBMP
{$ENDIF}
      ;
      rbbi.wID        := IDC_COMBOBOX;
      rbbi.hwndChild  := hwndChild;
      rbbi.lpText     := 'ComboBox';
{$IFDEF USEBMPICO}
      rbbi.hbmBack    := LoadBitmap(hInstance,MAKEINTRESOURCE(IDC_BACKBMP));
{$ENDIF}
      SendMessage(hwndRebar,RB_INSERTBAND,WPARAM(-1),LPARAM(@rbbi));
    end;

    // Create button
    hwndChild := CreateWindowEx(0,'button','Button',WS_CHILD or
      BS_PUSHBUTTON,0,0,100,25,hwndRebar,IDC_BUTTON,hInstance,nil);

    if(hwndChild <> 0) then begin
      // Assign default font
      SendMessage(hwndChild,WM_SETFONT,
        WPARAM(GetStockObject(DEFAULT_GUI_FONT)),MAKELPARAM(1,0));

      // Insert button as a band ...
      GetWindowRect(hwndChild,rc);

      ZeroMemory(@rbbi,sizeof(rbbi));
      rbbi.cbSize     := sizeof(TRebarBandInfo);
      rbbi.fMask      := RBBIM_SIZE or RBBIM_CHILD or RBBIM_CHILDSIZE or
        RBBIM_ID or RBBIM_STYLE or RBBIM_TEXT
{$IFDEF USEBMPICO}
        or RBBIM_IMAGE
{$ENDIF}
        ;
      rbbi.cxMinChild := 0;
      rbbi.cyMinChild := rc.Bottom - rc.Top;
      rbbi.cx         := 100;
      rbbi.fStyle     := RBBS_CHILDEDGE or RBBS_GRIPPERALWAYS;
      rbbi.wID        := IDC_BUTTON;
      rbbi.hwndChild  := hwndChild;
      rbbi.lpText     := 'Button';
{$IFDEF USEBMPICO}
      rbbi.iImage     := 0;
{$ENDIF}
      SendMessage(hwndRebar,RB_INSERTBAND,WPARAM(-1),LPARAM(@rbbi));
    end;

    // Create toolbar
    hwndChild := CreateWindowEx(0,TOOLBARCLASSNAME,nil,WS_CHILD or
      WS_VISIBLE or CCS_NODIVIDER or CCS_NORESIZE or CCS_NOPARENTALIGN or
      TBSTYLE_FLAT,0,0,0,0,hwndRebar,IDC_TOOLBAR,hInstance,nil);

    if(hwndChild <> 0) then begin
      // Insert buttons
      SendMessage(hwndChild,TB_BUTTONSTRUCTSIZE,sizeof(TTBBUTTON),0);
      SendMessage(hwndChild,TB_ADDBUTTONS,length(tbButtons),LPARAM(@tbButtons));

      // Load bitmap
      aBmp.hInst := HINST_COMMCTRL;
      aBmp.nID   := IDB_STD_SMALL_COLOR;
      SendMessage(hwndChild,TB_ADDBITMAP,0,LPARAM(@aBmp));

      // Show button texts
      SendMessage(hwndChild,TB_ADDSTRING,0,LPARAM(@szBtnText[1]));

      // Make partially visible buttons disappear!
      SendMessage(hwndChild,TB_SETEXTENDEDSTYLE,0,
        TBSTYLE_EX_HIDECLIPPEDBUTTONS);

      // Insert toolbar as a ribbon
      dwBtnSize  := SendMessage(hwndChild,TB_GETBUTTONSIZE,0,0);

      // Calculate ideal size
      iIdeal := 0;
      for i  := 0 to SendMessage(hwndChild,TB_BUTTONCOUNT,0,0) - 1 do begin
        SendMessage(hwndChild,TB_GETITEMRECT,WPARAM(i),LPARAM(@rc));
        inc(iIdeal,(rc.Right - rc.Left));
      end;

      ZeroMemory(@rbbi,sizeof(rbbi));
      rbbi.cbSize     := sizeof(TRebarBandInfo);
      rbbi.fMask      := RBBIM_SIZE or RBBIM_CHILD or RBBIM_CHILDSIZE or
        RBBIM_ID or RBBIM_STYLE or RBBIM_TEXT or RBBIM_IDEALSIZE;
      rbbi.cxMinChild := 0;
      rbbi.cyMinChild := HIWORD(dwBtnSize);
      rbbi.cx         := 100;
      rbbi.cxIdeal    := iIdeal;
      rbbi.fStyle     := RBBS_CHILDEDGE or RBBS_GRIPPERALWAYS or
        RBBS_BREAK or RBBS_USECHEVRON;
      rbbi.wID        := IDC_TOOLBAR;
      rbbi.hwndChild  := hwndChild;
      rbbi.lpText     := 'Toolbar';
      SendMessage(hwndRebar,RB_INSERTBAND,WPARAM(-1),LPARAM(@rbbi));

      // Passing "hwndChild" to the VAR parameter "hToolbar"
      hToolbar        := hwndChild;
    end;
  end;
end;


{$IFDEF LAYOUTSAVING}
procedure BeginUpdate(const wnd: HWND; UpdateState: boolean);
begin
  SendMessage(wnd,WM_SETREDRAW,WPARAM(not UpdateState),0);
end;

type
  rbBandArray = packed record
    Index,
    ID,
    Width : integer;
  end;
const
  szRegKey    = 'Software\Win32-API-Tutorials\Rebar-Demo';
  szValName   = 'RebarBandLayout';

procedure SaveLoadBandLayout(const rb: HWND; SaveSettings: boolean);
var
  reg        : HKEY;
  dwType,
  dwLen      : dword;
  bi         : TRebarBandInfo;
  i,
  bIdx       : integer;
  fba        : array of rbBandArray;
begin
  SetLength(fba,0);
  bIdx := SendMessage(rb,RB_GETBANDCOUNT,0,0);

  if(SaveSettings) then begin
    SetLength(fba,bIdx);

    for i := 0 to bIdx - 1 do begin
      // Get your current ID, size, and style
      ZeroMemory(@bi,sizeof(bi));
      bi.cbSize    := sizeof(TRebarBandInfo);
      bi.fMask     := RBBIM_ID or RBBIM_SIZE or RBBIM_STYLE;
      SendMessage(rb,RB_GETBANDINFO,i,LPARAM(@bi));

      fba[i].Index := i;
      fba[i].ID    := bi.wID;
      fba[i].Width := bi.cx;

      // when tape on new line (RBBS_BREAK attribute),
      // then secure the index as a negative number
      if(bi.fStyle and RBBS_BREAK <> 0) then
        fba[i].Index := 0 - fba[i].Index;
    end;

    // Writing values ??to the registry
    if(length(fba) > 0) then
      if(RegCreateKeyEx(HKEY_CURRENT_USER,szRegKey,0,nil,0,
        KEY_READ or KEY_WRITE,nil,reg,nil) = ERROR_SUCCESS) then
      try
        RegSetValueEx(reg,szValName,0,REG_BINARY,
          @fba[0],length(fba) * sizeof(rbBandArray));
      finally
        RegCloseKey(reg);
      end;
  end else begin
    if(RegOpenKeyEx(HKEY_CURRENT_USER,szRegKey,0,KEY_READ,
      reg) = ERROR_SUCCESS) then
    try
      dwType := REG_NONE;
      dwLen  := 0;

      // does the entry exist?
      if(RegQueryValueEx(reg,szValName,nil,@dwType,nil,
        @dwLen) = ERROR_SUCCESS) and
      // Is it of type REG_BINARY?
        (dwType = REG_BINARY) and
      // Does it even contain any data?
        ((dwLen > 0) and
      // are the data (= the number of bytes) without
      // Is the remainder divisible by the array size?
         (dwLen mod sizeof(rbBandArray) = 0) and
      // The bytes, divided by the
      // Array size, number of rebar bands?
         (dwLen div sizeof(rbBandArray) = dword(bIdx))) then
      begin
        // Set array size & load values
        SetLength(fba,dwLen div sizeof(rbBandArray));
        RegQueryValueEx(reg,szValName,nil,@dwType,@fba[0],@dwLen);
      end;
    finally
      RegCloseKey(reg);
    end;

    // Adjust rebar control
    if(length(fba) > 0) then begin
      BeginUpdate(rb,true);

      for i := 0 to length(fba) - 1 do
        if(abs(fba[i].Index) < SendMessage(rb,RB_GETBANDCOUNT,0,0)) and
          (SendMessage(rb,RB_IDTOINDEX,fba[i].ID,0) <> -1) then
        begin
          // Find the band index using the ID
          bIdx        := SendMessage(rb,RB_IDTOINDEX,fba[i].ID,0);

          // Get current style and size values
          ZeroMemory(@bi,sizeof(bi));
          bi.cbSize   := sizeof(TRebarBandInfo);
          bi.fMask    := RBBIM_STYLE or RBBIM_SIZE;
          SendMessage(rb,RB_GETBANDINFO,bIdx,LPARAM(@bi));

          // new width
          bi.cx       := fba[i].Width;

          // Band in a new line?
          if(fba[i].Index < 0) then
            bi.fStyle := bi.fStyle or RBBS_BREAK
          else
            bi.fStyle := bi.fStyle and not RBBS_BREAK;

          // Send new values ??to the rebar control
          SendMessage(rb,RB_SETBANDINFO,bIdx,LPARAM(@bi));

          // the band with the new index and
          // thereby moving
          SendMessage(rb,RB_MOVEBAND,bIdx,abs(fba[i].Index));
        end;

      BeginUpdate(rb,false);
    end;
  end;

  SetLength(fba,0);
end;
{$ENDIF}

//
// "WndProc"
//
const
  IDM_MAINMENU   = 100;
  IDM_EXIT       = 110;
  IDM_MINBAND1   = 120;
  IDM_MAXBAND1   = 121;
  IDM_MINREAL1   = 122;
  IDM_MAXREAL1   = 123;
var
  hRB,
  hTB            : HWND;
{$IFDEF USEBMPICO}
  hIG            : HIMAGELIST;
{$ENDIF}

function WndProc(wnd: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM): LRESULT;
  stdcall;
const
  fMinMax    : array[boolean]of uint =
    (RB_MINIMIZEBAND,RB_MAXIMIZEBAND);
  fCheckMenu : array[boolean]of cardinal =
    (MF_CHECKED,MF_UNCHECKED);
var
  p       : TPoint;
  hm      : HMENU;
  rc1,
  rc2,
  vis     : TRect;
  i       : integer;
  tb      : TTBButton;
  pText   : string;
begin
  Result := 0;

  case uMsg of
    WM_CREATE:
      begin
        BuildRebar(wnd,hRB,hTB{$IFDEF USEBMPICO},hIG{$ENDIF});
{$IFDEF LAYOUTSAVING}
        SaveLoadBandLayout(hRB,false);
{$ENDIF}
      end;
    WM_DESTROY:
      begin
{$IFDEF LAYOUTSAVING}
        SaveLoadBandLayout(hRB,true);
{$ENDIF}
{$IFDEF USEBMPICO}
        ImageList_Destroy(hIG);
{$ENDIF}
        PostQuitMessage(0);
      end;
    WM_SIZE:
      MoveWindow(hRB,0,0,LOWORD(lp),HIWORD(lp),true);
    WM_COMMAND:
      if(HIWORD(wp) = BN_CLICKED) then
        case LOWORD(wp) of
          IDC_BUTTON:
            MessageBox(wnd,'click',nil,0);
          IDM_EXIT:
            SendMessage(wnd,WM_CLOSE,0,0);
          IDM_MINBAND1,
          IDM_MAXBAND1:
            SendMessage(hRB,fMinMax[LOWORD(wp)=IDM_MAXBAND1],0,0);
          IDM_MINREAL1,
          IDM_MAXREAL1:
            begin
              i := SendMessage(hRB,RB_IDTOINDEX,IDC_COMBOBOX,0);
              if(i <> -1) then
                SendMessage(hRB,fMinMax[LOWORD(wp)=IDM_MAXREAL1],i,0);
            end;
(* Toolbar-Buttons *)
          IDC_NEWBTN..IDC_SAVEBTN:
            begin
              SetLength(pText,SendMessage(hTB,TB_GETBUTTONTEXT,
                WPARAM(LOWORD(wp)),0));
              SendMessage(hTB,TB_GETBUTTONTEXT,WPARAM(LOWORD(wp)),
                LPARAM(@pText[1]));

              MessageBox(wnd,pchar(Format('Button "%s" click',[pText])),
                nil,0);
            end;
        end;
    WM_NOTIFY:
      if(PNMRebarChevron(lp)^.hdr.code = RBN_CHEVRONPUSHED) then begin
        // Generate popup menu
        hm  := CreatePopupMenu;

        // Determine the length of the band
        // (However, this includes the ENTIRE tape.!) ...
        SendMessage(hRB,RB_GETRECT,WPARAM(PNMRebarChevron(lp)^.uBand),
          LPARAM(@rc1));

{$IFNDEF PSDK}
        // ... Therefore, determine the band border, and the rectangle
        // reduce to the actually usable area ...
        SendMessage(hRB,RB_GETBANDBORDERS,WPARAM(PNMRebarChevron(lp)^.uBand),
          LPARAM(@vis));
        inc(rc1.Left,vis.Left);
        inc(rc1.Top,vis.Top);
        dec(rc1.Right,vis.Right);
        dec(rc1.Bottom,vis.Bottom);

        // ... and subtract the width of the chevron as well.
        dec(rc1.Right,
          PNMRebarChevron(lp)^.rc.Right -
          PNMRebarChevron(lp)^.rc.Left);
{$ENDIF}

        // Process all tool buttons
        for i := 0 to SendMessage(hTB,TB_BUTTONCOUNT,0,0) - 1 do begin
          // Determine button type
          ZeroMemory(@tb,sizeof(tb));
          SendMessage(hTB,TB_GETBUTTON,WPARAM(i),LPARAM(@tb));

          // Determine button-TRect, & (since it's client-dependent)
          // bring to the position of the rebar
          SendMessage(hTB,TB_GETITEMRECT,WPARAM(i),LPARAM(@rc2));
{$IFNDEF PSDK}
          OffsetRect(rc2,rc1.Left,rc1.Top);
{$ENDIF}

          // Determine visible part
          IntersectRect(vis,rc1,rc2);

          // Create menu item (ignore separators!)
          if(not EqualRect(vis,rc2)) and
            (tb.fsStyle <> BTNS_SEP) then
          begin
            // Get button text
            SetLength(pText,SendMessage(hTB,TB_GETBUTTONTEXT,
              WPARAM(tb.idCommand),0)+1);
            SendMessage(hTB,TB_GETBUTTONTEXT,WPARAM(tb.idCommand),
              LPARAM(@pText[1]));

            AppendMenu(hm,MF_STRING,tb.idCommand,pchar(pText));
          end;
        end;

        // Get chevron coordinates, ...
        p.X := PNMRebarChevron(lp)^.rc.Left;
        p.Y := PNMRebarChevron(lp)^.rc.Bottom;

        // ... & convert to screen values, or.
        // Show the menu only if items are present.
        if(ClientToScreen(wnd,p)) and (GetMenuItemCount(hm) > 0) then
          TrackPopupMenu(hm,TPM_LEFTALIGN,p.X,p.Y,0,wnd,nil);

        DestroyMenu(hm);
      end;
    else
      Result := DefWindowProc(wnd,uMsg,wp,lp);
  end;
end;


//
// "WinMain"
//
const
  szClassName = 'RebarWndClass';
  szAppName   = 'Tool Bar';
var
  aWnd        : HWND;
  msg         : TMsg;
  iccex       : TInitCommonControlsEx = (
    dwSize:sizeof(TInitCommonControlsEx);
    dwICC:ICC_COOL_CLASSES or ICC_BAR_CLASSES;);
  wc          : TWndClassEx = (
    cbSize:sizeof(TWndClassEx);
    lpfnWndProc:@WndProc;
    hbrBackground:COLOR_WINDOW+1;
    lpszMenuName:MAKEINTRESOURCE(IDM_MAINMENU);
    lpszClassName:szClassname;);
begin
  // Coolbar (aka Rebar), & Initialize Toolbar
  InitCommonControlsEx(iccex);

  // Register window class
  wc.hInstance     := hInstance;
  wc.hIcon         := LoadIcon(0,IDI_APPLICATION);
  wc.hCursor       := LoadCursor(0,IDC_ARROW);
  wc.hbrBackground := GetSysColorBrush(COLOR_3DFACE);
  if(RegisterClassEx(wc) = 0) then exit;

  // Create window & display
  aWnd := CreateWindowEx(0,szClassName,szAppName,WS_OVERLAPPEDWINDOW,
    integer(CW_USEDEFAULT),integer(CW_USEDEFAULT),integer(CW_USEDEFAULT),
    integer(CW_USEDEFAULT),0,0,hInstance,nil);
  if(aWnd = 0) then exit;
  ShowWindow(aWnd,SW_SHOW);
  UpdateWindow(aWnd);

  // Message loop
  while(GetMessage(msg,0,0,0)) do begin
    TranslateMessage(msg);
    DispatchMessage(msg);
  end;
end.