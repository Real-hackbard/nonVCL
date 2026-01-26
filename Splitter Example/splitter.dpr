program splitter;

uses
  Windows,
  Messages,
  CommCtrl,
  ShellAPI,
  ShlObj,
  ActiveX,
  MSysUtils in 'MSysUtils.pas',
  ShellHelper in 'ShellHelper.pas';


procedure BeginUpdate(const wnd: HWND; fBeginUpdate: boolean);
begin
  SendMessage(wnd,WM_SETREDRAW,WPARAM(not fBeginUpdate),0);
end;

//
// scan a folder
//
procedure FillTreeView(const hTV, hLV: HWND);

  function CreateTreeNode(const iDesktopFolder: IShellFolder;
    hParent: HTREEITEM; pidlNode: PItemIdList): HTREEITEM;
  var
    tvi                     : TTVInsertStruct;
    szCaption               : string;
  begin
    // get visual name, ...
    szCaption               := GetDisplayName(iDesktopFolder,pidlNode);

    // ... & create TreeNode
    tvi.hParent             := hParent;
    tvi.hInsertAfter        := TVI_SORT;
    tvi.item.mask           := TVIF_TEXT or TVIF_IMAGE or
      TVIF_SELECTEDIMAGE;
    tvi.item.iImage         := GetShellImg(iDesktopFolder,pidlNode,false);
    tvi.item.iSelectedImage := GetShellImg(iDesktopFolder,pidlNode,true);
    tvi.item.pszText        := pchar(szCaption);
    Result                  := TreeView_InsertItem(hTV,tvi);
  end;

  procedure CreateListItem(const iDesktopFolder: IShellFolder;
    pidlNode: PItemIdList; var loop: integer);
  var
    szCaption    : string;
    szFullPath   : string;
    lvi          : TLVItem;
  begin
    szCaption    := GetDisplayName(iDesktopFolder,pidlNode);
    szFullPath   := GetDisplayName(iDesktopFolder,pidlNode,
      SHGDN_NORMAL or SHGDN_FORPARSING);

    lvi.mask     := LVIF_TEXT or LVIF_IMAGE;
    lvi.iItem    := loop;
    lvi.iSubItem := 0;
    lvi.pszText  := pchar(szCaption);

    lvi.iImage := GetShellImg(szFullPath,false);
    //lvi.iImage := GetShellImg(iDesktopFolder,pidlNode,false);

    ListView_InsertItem(hLV,lvi);

    // increase counter
    inc(loop);
  end;

  procedure Scan(const hSuperParent, hParent: HTREEITEM;
    iRootFolder: IShellFolder; pidlParent: PItemIdList; pMalloc: IMalloc;
    var loop: integer);
  var
    tv          : HTREEITEM;
    iFolder     : IShellFolder;
    ppEnum      : IEnumIdList;
    pidlItem    : PItemIdList;
    uAttr,
    celtFetched : ULONG;
  begin
    if(iRootFolder.BindToObject(pidlParent,nil,IID_IShellFolder,
      iFolder) = S_OK) then
    begin
      if(iFolder.EnumObjects(0,SHCONTF_FOLDERS or SHCONTF_NONFOLDERS or
        SHCONTF_INCLUDEHIDDEN,ppEnum) = S_OK) then
      begin
        while(ppEnum.Next(1,pidlItem,celtFetched) = S_OK) and
             (celtFetched = 1) do
        begin
          iFolder.GetAttributesOf(1,pidlItem,uAttr);

          // create a List-View item if you are still at the 1st level
          if(hParent = hSuperParent) then
            CreateListItem(iFolder,pidlItem,loop);

          // it's a folder
          if(uAttr and SFGAO_FOLDER <> 0) then
          begin
            tv := CreateTreeNode(iFolder,hParent,pidlItem);
            Scan(hSuperParent,tv,iFolder,pidlItem,pMalloc,loop);
          end;

          pMalloc.Free(pidlItem);
        end;
      end;

      iFolder := nil;
    end;
  end;

var
  pMalloc  : IMalloc;
  iDesktop : IShellFolder;
  pidlRoot : PItemIdList;
  tv       : HTREEITEM;
  loop     : integer;
begin
  // clear Tree-View, & "BeginUpdate"
  TreeView_DeleteAllItems(hTV);
  BeginUpdate(hTV,true);

  // need an IShellFolder interface to enumerate
  if(SHGetMalloc(pMalloc) = NOERROR) and
    (SHGetDesktopFolder(iDesktop) = NOERROR) then
  try
    // where are my documents?
    SHGetSpecialFolderLocation(hTV,CSIDL_PERSONAL,pidlRoot);
    if(pidlRoot = nil) then exit;

    // insert root, ...
    tv   := CreateTreeNode(iDesktop,nil,pidlRoot);
    if(tv <> nil) then
    begin
      // ... & scan, ...
      loop := 0;
      Scan(tv,tv,iDesktop,pidlRoot,pMalloc,loop);

      // ... & select 1st item
      TreeView_Expand(hTV,tv,TVE_EXPAND);
      TreeView_SelectItem(hTV,tv);
    end;

    // free "pidlRoot"
    if(pidlRoot <> nil) then pMalloc.Free(pidlRoot);
    pidlRoot := nil;
  finally
    iDesktop := nil;
    pMalloc  := nil;
  end;

  // "EndUpdate"
  BeginUpdate(hTV,false);
end;


{$HINTS OFF}
{$WARNINGS OFF}

procedure DrawTrackSplit(const hWnd: HWND; x, y, Width, Height: longint;
  bPattern: boolean = true);
const
  DotBits : array[0..7] of Word =
    ($5555,$AAAA,$5555,$AAAA,$5555,$AAAA,$5555,$AAAA);
var
  dc      : HDC;
  hbr     : HBRUSH;
  bmp     : HBITMAP;
begin
  dc      := GetDCEx(hWnd,0,DCX_CACHE or DCX_CLIPSIBLINGS or
    DCX_LOCKWINDOWUPDATE);

  if bPattern then
  begin
    bmp := CreateBitmap(8, 8, 1, 1, @DotBits);
    hbr := SelectObject(dc, CreatePatternBrush(bmp));
    DeleteObject(bmp);
  end;

  PatBlt(dc, x, y, Width, Height, PATINVERT);
  if bPattern then
    DeleteObject(SelectObject(dc, hbr));

  ReleaseDC(hWnd, dc);
end;

{$WARNINGS ON}
{$HINTS ON}


// -- WndProc ------------------------------------------------------------------

//
// "WndProc"
//
const
  SB_SIMPLEID   = $00ff;
  wWidth        =   600;
  wHeight       =   400;

  IDC_TREEVIEW  =     1;
  IDC_STATUSBAR =     2;
  IDC_LV        =     3;
  IDC_MEMO      =     4;

  MINVSPLIT     =   190;
  MINHSPLIT     =   100;
  SPLITWIDTH    =     3;
var
  hTreeview,
  hLV,
  hMemo,
  hStatusbar    : HWND;
  hMemoFont     : HGDIOBJ;

  vSplitPos     : integer = MINVSPLIT + 30;
  hSplitPos     : integer = wHeight - (MINHSPLIT + 50);
  fVTrackSplit  : boolean = false;
  fHTrackSplit  : boolean = false;


{.$DEFINE SNAPFX}


function WndProc(wnd: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM): LRESULT;
  stdcall;
var
  rc         : TRect;
  i          : integer;
  fi         : TSHFileInfo;
  x,
  y          : longint;
  hSmallImg,
  hBigImg    : HIMAGELIST;
begin
  Result := 0;

  case uMsg of
    WM_CREATE:
      begin
        // create simple statusbar
        hStatusbar := CreateWindowEx(0,STATUSCLASSNAME,nil,
          WS_VISIBLE or WS_CHILD,0,0,0,0,wnd,IDC_STATUSBAR,hInstance,nil);
        SendMessage(hStatusbar,SB_SIMPLE,WPARAM(true),0);

        // create Tree-View
        hTreeView  := CreateWindowEx(WS_EX_CLIENTEDGE,WC_TREEVIEW,nil,
          WS_VISIBLE or WS_CHILD or TVS_HASLINES or TVS_LINESATROOT
          or TVS_HASBUTTONS,0,0,10,10,wnd,IDC_TREEVIEW,hInstance,nil);
        if(hTreeView = 0) then
          SendMessage(wnd,WM_CLOSE,0,0);

        // create List-View
        hLV        := CreateWindowEx(WS_EX_CLIENTEDGE,WC_LISTVIEW,nil,
          WS_VISIBLE or WS_CHILD or LVS_ICON or LVS_AUTOARRANGE or
          LVS_SHAREIMAGELISTS,0,0,10,10,wnd,IDC_LV,hInstance,nil);

        // create Memo
        hMemo      := CreateWindowEx(WS_EX_CLIENTEDGE,'Edit',
          'A memo with no particular meaning',WS_CHILD or WS_VISIBLE or
          WS_VSCROLL or ES_MULTILINE or ES_NOHIDESEL or ES_READONLY,
          0,0,0,0,wnd,IDC_MEMO,hInstance,nil);
        hMemoFont  := GetStockObject(DEFAULT_GUI_FONT);
        if(hMemoFont <> 0) then
          SendMessage(hMemo,WM_SETFONT,WPARAM(hMemoFont),0);

        // get System's imagelist
        ZeroMemory(@fi,sizeof(TSHFileInfo));
        hSmallImg := HIMAGELIST(SHGetFileInfo('',0,fi,sizeof(fi),
          SHGFI_SYSICONINDEX or SHGFI_SMALLICON));
        if(hSmallImg <> 0) then
          TreeView_SetImageList(hTreeview,hSmallImg,TVSIL_NORMAL);
        hBigImg := HIMAGELIST(SHGetFileInfo('',0,fi,sizeof(fi),
          SHGFI_SYSICONINDEX or SHGFI_ICON));
        if(hBigImg <> 0) then
          ListView_SetImageList(hLV,hBigImg,LVSIL_NORMAL);

        // scan current drive
        SetCursor(LoadCursor(0,IDC_WAIT));
        FillTreeView(hTreeview,hLV);
        SetCursor(LoadCursor(0,IDC_ARROW));
      end;
    WM_DESTROY:
      begin
        DeleteObject(hMemoFont);
        PostQuitMessage(0);
      end;
    WM_GETMINMAXINFO:
      begin
        PMinMaxInfo(lp)^.ptMinTrackSize.X := wWidth;
        PMinMaxInfo(lp)^.ptMinTrackSize.Y := wHeight;
      end;

(* Begin Splitter *)

    WM_SIZE:
      begin
        if(wp <> SIZE_MINIMIZED) then
        begin
          // update statusbar
          MoveWindow(hStatusbar,0,HIWORD(lp),LOWORD(lp),HIWORD(lp),true);
          GetClientRect(hStatusbar,rc);
          i := rc.Bottom - rc.Top;

          // get client rect,
          GetClientRect(wnd,rc);

          // re-set splitter position (if necessary)
{$IFDEF SNAPFX}
          if(vSplitPos >= rc.Right - SPLITWIDTH) then
            vSplitPos := rc.Right - SPLITWIDTH;
          if(hSplitPos >= rc.Bottom - i - SPLITWIDTH) then
            hSplitPos := rc.Bottom - i - SPLITWIDTH;
{$ELSE}
          if(vSplitPos >= rc.Right - MINVSPLIT) then
            vSplitPos := rc.Right - MINVSPLIT;
          if(hSplitPos >= rc.Bottom - i - MINHSPLIT) then
            hSplitPos := rc.Bottom - i - MINHSPLIT;
{$ENDIF}
          // resize & move Tree-View
          MoveWindow(hTreeView,rc.Left,rc.Top,vSplitPos,hSplitPos,true);

          // resize & move List-View
          MoveWindow(hLV,vSplitPos + SPLITWIDTH,rc.Top,rc.Right -
            (vSplitPos + SPLITWIDTH),hSplitPos,true);

          // resize & move Memo
          MoveWindow(hMemo,rc.Left,hSplitPos + SPLITWIDTH,rc.Right,
            rc.Bottom - i - (hSplitPos + SPLITWIDTH),true);
        end;
      end;
    WM_LBUTTONDOWN:
      begin
        // get cursor position, & client rect
        x := LOWORD(lp);
        y := HIWORD(lp);
        GetClientRect(wnd,rc);

        // vertical splitter
        if(x >= vSplitPos) and (x <= vSplitPos + SPLITWIDTH) then
        begin
          SetCursor(LoadCursor(0,IDC_SIZEWE));
          SetCapture(wnd);
          DrawTrackSplit(wnd,vSplitPos,0,SPLITWIDTH,hSplitPos);
          fVTrackSplit := true;
        end
        // horizontal splitter
        else if(y >= hSplitPos) and (y <= hSplitPos + SPLITWIDTH) then
        begin
          SetCursor(LoadCursor(0,IDC_SIZENS));
          SetCapture(wnd);
          DrawTrackSplit(wnd,rc.Left,hSplitPos,rc.Right,SPLITWIDTH);
          fHTrackSplit := true;
        end;
      end;
    WM_LBUTTONUP:
      if fVTrackSplit or fHTrackSplit then
        ReleaseCapture;
    WM_MOUSEMOVE:
      begin
        // get statusbar height
        GetClientRect(hStatusbar,rc);
        i := rc.Bottom - rc.Top;

        // get cursor position, & client rect
        x := LOWORD(lp);
        y := HIWORD(lp);
        GetClientRect(wnd,rc);

        // vertical splitter
        if(fVTrackSplit) then
        begin
{$IFDEF SNAPFX}
          // Eugen's Snap FX
          if(x < rc.Left + 50) then x := rc.Left + SPLITWIDTH
            else if(x > rc.Right - 50) then x := rc.Right - SPLITWIDTH;
{$ELSE}
          // catch the splitter, if it's moved too much
          if(x < MINVSPLIT) then x := MINVSPLIT
            else if(x > rc.Right - MINVSPLIT) then x := rc.Right - MINVSPLIT;
{$ENDIF}
          // redraw splitter "shadow"
          if(vSplitPos + 1 <> x) then
          begin
            DrawTrackSplit(wnd,vSplitPos,0,SPLITWIDTH,hSplitPos);
            inc(vSplitPos,x - vSplitPos - 1);
            DrawTrackSplit(wnd,vSplitPos,0,SPLITWIDTH,hSplitPos);
          end;
        end
        // horizontal splitter
        else if(fHTrackSplit) then
        begin
{$IFDEF SNAPFX}
          if(y < rc.Top + 50) then y := rc.Top + SPLITWIDTH
            else if(y > rc.Bottom - i - 50) then
              y := rc.Bottom - i - SPLITWIDTH;
{$ELSE}
          // catch the splitter
          if(y < rc.Top + MINHSPLIT) then y := rc.Top + MINHSPLIT
            else if(y > rc.Bottom - i - MINHSPLIT) then
              y := rc.Bottom - i - MINHSPLIT;
{$ENDIF}

          // redraw splitter "shadow"
          if(hSplitPos + 1 <> y) then
          begin
            DrawTrackSplit(wnd,rc.Left,hSplitPos,rc.Right,SPLITWIDTH);
            inc(hSplitPos,y - hSplitPos - 1);
            DrawTrackSplit(wnd,rc.Left,hSplitPos,rc.Right,SPLITWIDTH);
          end;
        end
        // change cursor to show that there's the splitter
        else if(x >= vSplitPos) and (x <= vSplitPos + SPLITWIDTH) then
          SetCursor(LoadCursor(0,IDC_SIZEWE))
        else if(y >= hSplitPos) and (y <= hSplitPos + SPLITWIDTH) then
          SetCursor(LoadCursor(0,IDC_SIZENS));
      end;
    WM_CAPTURECHANGED:
      begin
        // get client rect
        GetClientRect(wnd,rc);

        // update the controls by calling WM_SIZE
        if(fVTrackSplit) then
        begin
          DrawTrackSplit(wnd,vSplitPos,0,SPLITWIDTH,hSplitPos);
          SendMessage(wnd,WM_SIZE,0,0);
          fVTrackSplit:= false;
        end
        else if(fHTrackSplit) then
        begin
          DrawTrackSplit(wnd,rc.Left,hSplitPos,rc.Right,SPLITWIDTH);
          SendMessage(wnd,WM_SIZE,0,0);
          fHTrackSplit:= false;
        end;
      end;

(* End Splitter *)

    else
      Result := DefWindowProc(wnd,uMsg,wp,lp);
  end;
end;


// -- WinMain ------------------------------------------------------------------

const
  szClassname = 'SplitWndClass';
  szAppname   = 'Splitter Example';
var
  wc   : TWndClassEx =
    (cbSize:sizeof(TWndClassEx);
     Style:CS_HREDRAW or CS_VREDRAW;
     lpfnWndProc:@WndProc;
     cbClsExtra:0;
     cbWndExtra:0;
     hbrBackground:COLOR_APPWORKSPACE;
     lpszMenuName:nil;
     lpszClassName:szClassName;);
  icc  : TInitCommonControlsEx =
    (dwSize:sizeof(TInitCommonControlsEx);
     dwICC:ICC_TREEVIEW_CLASSES or ICC_LISTVIEW_CLASSES;);
  hwndMsg  : TMsg;
  aWnd     : HWND;

begin
  if(CoInitializeEx(nil,COINIT_APARTMENTTHREADED) = S_OK) then
  try
    // "Common Controls" initialisieren
    InitCommonControlsEx(icc);

    // Register class
    wc.hInstance := hInstance;
    wc.hIcon     := LoadIcon(0,IDI_WINLOGO);
    wc.hCursor   := LoadCursor(0,IDC_ARROW);
    if(RegisterClassEx(wc) = 0) then exit;

    // Create Window
    aWnd := CreateWindowEx(0,szClassname,szAppname,WS_VISIBLE or
      WS_OVERLAPPEDWINDOW,integer(CW_USEDEFAULT),integer(CW_USEDEFAULT),
      wWidth,wHeight,0,0,hInstance,nil);
    if(aWnd = 0) then exit;
    ShowWindow(aWnd,SW_SHOW);
    UpdateWindow(aWnd);

    // Message loop
    while(GetMessage(hwndMsg,0,0,0)) do
    begin
      TranslateMessage(hwndMsg);
      DispatchMessage (hwndMsg);
    end;
  finally
    CoUninitialize;
  end;
end.