{.$DEFINE SIMPLE}

//
program Treeview;

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
// Scan the selected drive for all folders
//
type
  TFolderId = class
  private
    FPidl   : PItemIdList;
    FFolder : IShellFolder;
  public
    constructor Create(const pidlNode: PItemIdList; iFolder: IShellFolder);
    destructor Destroy; override;
    property pidl: PItemIdList read FPidl;
    property Folder: IShellFolder read FFolder;
  end;

constructor TFolderId.Create(const pidlNode: PItemIdList;
  iFolder: IShellFolder);
begin
  FFolder := iFolder;
  FPidl   := CopyPIDL(pidlNode);
end;

destructor TFolderId.Destroy;
var
  pm : IMalloc;
begin
  if(SHGetMalloc(pm) = NOERROR) then
  try
    pm.Free(FPidl);
    FPidl := nil;
  finally
    pm    := nil;
  end;

  FFolder := nil;
end;


procedure FreeTV(const hTV: HWND);

  procedure FreeTreeNode(const pn: HTREEITEM);
  var
    tn        : TTVItem;
    fid       : TFolderId;
  begin
    // "lParam"-Read out value, ...
    tn.mask   := TVIF_HANDLE or TVIF_PARAM;
    tn.hItem  := pn;
    TreeView_GetItem(hTV,tn);

    // ... & experimentally using the "TFolderId" class
    // access and release them
    fid       := TFolderId(tn.lParam);
    if(fid <> nil) then FreeAndNil(fid);

    tn.lParam := 0;
    TreeView_SetItem(hTV,tn);
  end;

  procedure ClearChildNodes(const parent: HTREEITEM);
  var
    p : HTREEITEM;
  begin
    // Determine any subnodes that may exist., ...
    p := TreeView_GetChild(hTV,parent);
    while(p <> nil) do
    begin
    // ... & release, ...
      FreeTreeNode(p);
    // ... & Continue searching for sub-sub-... nodes
      ClearChildNodes(p);

      p := TreeView_GetNextSibling(hTV,p);
    end;

    // release the current node
    FreeTreeNode(parent);
  end;

var
  parent : HTREEITEM;
begin
  parent := TreeView_GetRoot(hTV);
  while(parent <> nil) do
  begin
    ClearChildNodes(parent);
    parent := TreeView_GetNextItem(hTV,parent,TVGN_NEXT);
  end;

  TreeView_DeleteAllItems(hTV);
end;

function CreateTreeNode(const hTV: HWND; iDesktopFolder: IShellFolder;
  hParent: HTREEITEM; pidlNode: PItemIdList): HTREEITEM;
var
  tvi                     : TTVInsertStruct;
  szCaption               : string;
  uAttr                   : ULONG;
  fid                     : TFolderId;
begin
  // the visual name, as you know it from Explorer, ...
  szCaption               := GetDisplayName(iDesktopFolder,pidlNode);

  // Create nodes
  tvi.hParent             := hParent;
  tvi.hInsertAfter        := TVI_SORT;
  tvi.item.mask           := TVIF_TEXT or TVIF_IMAGE or
    TVIF_SELECTEDIMAGE;
  tvi.item.iImage         := GetShellImg(iDesktopFolder,pidlNode,false);
  tvi.item.iSelectedImage := GetShellImg(iDesktopFolder,pidlNode,true);
  tvi.item.pszText        := pchar(szCaption);

  // there are subfolders?
  uAttr                   := SFGAO_CONTENTSMASK;

  if(iDesktopFolder.GetAttributesOf(1,pidlNode,uAttr) = S_OK) and
    (SFGAO_HASSUBFOLDER and uAttr <> 0) then
  begin
    tvi.item.mask         := tvi.item.mask or TVIF_CHILDREN;
    tvi.item.cChildren    := 1;

    // "TFolderId"-Create class
    fid                   := TFolderId.Create(pidlNode,iDesktopFolder);
    if(fid <> nil) then
    begin
      tvi.item.mask       := tvi.item.mask or TVIF_PARAM;
      tvi.item.lParam     := LPARAM(fid);
    end;

    // NOTE: This class is not needed if the folder
    // It doesn't even contain any subfolders. Then there's nothing.
    // to fold out, so why waste storage space?? :o)
  end;

  Result                  := TreeView_InsertItem(hTV,tvi);
end;

procedure Scan(const hTV: HWND; hParent: HTREEITEM; iRootFolder: IShellFolder;
  pidlParent: PItemIdList; pMalloc: IMalloc);
var
  iFolder     : IShellFolder;
  ppEnum      : IEnumIdList;
  pidlItem    : PItemIdList;
  celtFetched : ULONG;
begin
  SetCursor(LoadCursor(0,IDC_APPSTARTING));

  // bind to a subordinate "IShellFolder" interface, ...
  if(iRootFolder.BindToObject(pidlParent,nil,IID_IShellFolder,
    iFolder) = S_OK) then
  begin
  // ... & start the enumeration
    if(iFolder.EnumObjects(0,SHCONTF_FOLDERS or SHCONTF_INCLUDEHIDDEN,
      ppEnum) = S_OK) then
    begin
      // loop as long as elements are present
      while(ppEnum.Next(1,pidlItem,celtFetched) = S_OK) and
           (celtFetched = 1) do
      begin
        // Create nodes
        CreateTreeNode(hTV,iFolder,hParent,pidlItem);

        // Release the used "PItemIdList", ...
        pMalloc.Free(pidlItem);

        pidlItem := nil;
      end;
    end;
  end;

  SetCursor(LoadCursor(0,IDC_ARROW));
end;

procedure FillTreeView(hTV: HWND; const drv: BYTE);
var
  pMalloc  : IMalloc;
  iDesktop : IShellFolder;
  pidlRoot : PItemIdList;
  tv       : HTREEITEM;
begin
  // Incorrect drive letter!
  if not(drv in[3..26]) then exit;
  // (Currently, Windows only recognizes drive letters from A to Z.;
  // Typically, A and B are floppy disk drives.)

  // clear Tree-View, & "BeginUpdate"
  FreeTV(hTV);
  BeginUpdate(hTV,true);

  if(SHGetMalloc(pMalloc) = NOERROR) and
    (SHGetDesktopFolder(iDesktop) = NOERROR) then
  try
    SHGetSpecialFolderLocation(hTV,CSIDL_DRIVES,pidlRoot);
    if(pidlRoot <> nil) then
    begin
      tv     := CreateTreeNode(hTV,iDesktop,nil,pidlRoot);
      pMalloc.Free(pidlRoot);
    end
    else
      tv     := nil;

    // Determine the "PItemIdList" of the drive
    GetIdFromPath(iDesktop,CHR(drv + 64) + ':\',pidlRoot);
    if(pidlRoot = nil) then exit;

    // Insert root, ...
    tv       := CreateTreeNode(hTV,iDesktop,tv,pidlRoot);

    // ... & Scan drive, ...
    Scan(hTV,tv,iDesktop,pidlRoot,pMalloc);

    // ... & Select the first item
    TreeView_Expand(hTV,tv,TVE_EXPAND);
    TreeView_SelectItem(hTV,tv);

    // "pidlRoot" release
    if(pidlRoot <> nil) then pMalloc.Free(pidlRoot);
    pidlRoot := nil;
  finally
    pMalloc  := nil;
    iDesktop := nil;
  end;

  // "EndUpdate"
  BeginUpdate(hTV,false);
end;

procedure ScanTreeViewAgain(const hTV: HWND; fid: TFolderId;
  parentNode: HTREEITEM);
var
  pMalloc : IMalloc;
  tn      : TTVItem;
begin
  // Shell patch, because TVN_ITEMEXPANDING was already used in the
  // Filling is triggered. Here it is determined whether
  // that subnodes even exist
  if(TreeView_GetChild(hTV,parentNode) <> nil) then exit;

  if(fid <> nil) and
    (SHGetMalloc(pMalloc) = NOERROR) then
  try
    Scan(hTV,parentNode,fid.Folder,fid.pidl,pMalloc);
  finally
    pMalloc := nil;
  end;

  // Remove node symbol if necessary.
  if(TreeView_GetChild(hTV,parentNode) = nil) then
  begin
    tn.mask      := TVIF_HANDLE or TVIF_CHILDREN;
    tn.hItem     := parentNode;
    tn.cChildren := 0;
    TreeView_SetItem(hTV,tn);
  end;
end;

function GetDrivesVisualName(const Drive: string): string;
var
  iDesktop : IShellFolder;
  pMalloc  : IMalloc;
  pidl     : PItemIdList;
begin
  Result   := '';

  if(SHGetMalloc(pMalloc) = NOERROR) and
    (SHGetDesktopFolder(iDesktop) = NOERROR) then
  try
    if(GetIdFromPath(iDesktop,Drive,pidl)) then
      Result := GetDisplayName(iDesktop,pidl);

    if(pidl <> nil) then pMalloc.Free(pidl);
  finally
    iDesktop := nil;
    pMalloc  := nil;
  end;
end;


//
// Change the style of the Treeview control
//
function SetStyle(const hTV: HWND; dwNewStyle: dword): dword;
var
  dwStyle : dword;
begin
  dwStyle := GetWindowLong(hTV,GWL_STYLE);

  // Is the style already set?
  // no, add ->
  if(dwStyle and dwNewStyle = 0) then
    SetWindowLong(hTV,GWL_STYLE,dwStyle or dwNewStyle)
  // yes, remove ->
  else
    SetWindowLong(hTV,GWL_STYLE,dwStyle and not dwNewStyle);

  // new style as a functional result
  Result := GetWindowLong(hTV,GWL_STYLE);
end;

//
// Copy entries
//
var
  CopyResult : boolean = true;

procedure CopyItems(const hTV: HWND; itemFrom, itemTo : HTREEITEM);
var
  tv      : TTVItem;
  tvi     : TTVInsertStruct;
  buf     : array[0..MAX_PATH]of char;
  parent,
  child   : HTREEITEM;
  oldFid,
  newFid  : TFolderId;
begin
  // Exit the function if an error occurred.
  if(not CopyResult) then exit;

  // Find saved item
  tv.mask            := TVIF_HANDLE or TVIF_TEXT or TVIF_CHILDREN or
    TVIF_IMAGE or TVIF_SELECTEDIMAGE or TVIF_PARAM;
  tv.hItem           := itemFrom;
  tv.pszText         := buf;
  tv.cchTextMax      := sizeof(buf);
  CopyResult         := TreeView_GetItem(hTV,tv);

  // copy
  if(CopyResult) then
  begin
    oldFid           := TFolderId(tv.lParam);
    newFid           := TFolderId.Create(oldFid.pidl,oldFid.Folder);
    if(newFid <> nil) then
      tv.lParam      := LPARAM(newFid)
    else
    begin
      tv.mask        := tv.mask and not TVIF_PARAM;
      tv.lParam      := 0;
    end;

    tvi.hParent      := itemTo;
    tvi.hInsertAfter := TVI_SORT;
    tvi.item         := tv;
    parent           := TreeView_InsertItem(hTV,tvi);
    CopyResult       := (parent <> nil);

    // Subordinate items are available
    if(CopyResult) and (tv.cChildren = 1) then
    begin
      // Find the first subordinate item, ...
      child          := TreeView_GetChild(hTV,itemFrom);

      while(child <> nil) do
      begin
        // ... & copy by calling this procedure
        CopyItems(hTV,child,parent);

        // because we are now one level deeper, we must
        // We call up "GetNextSibling" to get all items
        // to determine this level
        child        := TreeView_GetNextSibling(hTV,child);
      end;
    end;
  end;
end;


// -- WndProc ------------------------------------------------------------------

//
// "WndProc"
//
type
  PTVKeyDown      = ^TTVKeyDown; 
                                 // in "CommCtrl.pas"

const
  SB_SIMPLEID     = $00ff;
  wWidth          =   300;
  wHeight         =   440;

  IDC_TREEVIEW    =     1;
  IDC_STATUSBAR   =     2;
  IDM_EXIT        =    27;
  IDM_LINES       =   101;
  IDM_BUTTONS     =   102;
  IDM_HOTTRACK    =   103;
  IDM_MOVE        =   200;
  IDM_COPY        =   201;
var
  hTreeview,
  hStatusbar      : HWND;
  hSmallImg,
  hDragImgList    : HIMAGELIST;
  DragMode        : boolean = false;
  hOldItem        : HTREEITEM;


function WndProc(wnd: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM): LRESULT;
  stdcall;
const
  fCheckState : array[boolean]of cardinal = (0,MF_CHECKED);
var
  rc          : TRect;
  i           : integer;
  buf         : array[0..MAX_PATH]of char;
  fi          : TSHFileInfo;
  tvhit       : TTVHitTestInfo;
  HitHandle   : HTreeItem;
  menu,
  hSubMenu    : HMENU;
  p           : TPoint;
  tv          : TTVItem;
  iCurDrive   : byte;
  fid         : TFolderId;
begin
  Result := 0;

  case uMsg of
    WM_CREATE:
      begin
        // Determine current drive
        iCurDrive  := BYTE(paramstr(0)[1]) - 64;

        // Create a menu using the local hard drives
        menu       := CreateMenu;
        hSubMenu   := CreatePopupMenu;
        for i      := 3 to 26 do
          if(GetDriveType(pchar(CHR(i+64)+':\')) = DRIVE_FIXED) then
            AppendMenu(hSubMenu,MF_STRING or fCheckState[i=iCurDrive],
            i,pchar(GetDrivesVisualName(CHR(i+64)+':\')));
        AppendMenu(menu,MF_STRING or MF_POPUP,DWORD(hSubMenu),
          'Harddisks');

        // Create a menu with the view modes
        hSubMenu   := CreatePopupMenu;
        AppendMenu(hSubMenu,MF_STRING or MF_CHECKED,IDM_LINES,'Lines');
        AppendMenu(hSubMenu,MF_STRING or MF_CHECKED,IDM_BUTTONS,'Buttons');
        AppendMenu(hSubMenu,MF_STRING,IDM_HOTTRACK,'Hottrack');
        AppendMenu(menu,MF_STRING or MF_POPUP,DWORD(hSubMenu),'View');

        // "End"
        AppendMenu(menu,MF_STRING,IDM_EXIT,'End');
        SetMenu(wnd,menu);

        // Statusbar (simpel)
        hStatusbar := CreateWindowEx(0,STATUSCLASSNAME,nil,
          WS_VISIBLE or WS_CHILD,0,0,0,0,wnd,IDC_STATUSBAR,hInstance,nil);
        SendMessage(hStatusbar,SB_SIMPLE,WPARAM(true),0);

        // Treeview create
        hTreeView  := CreateWindowEx(WS_EX_CLIENTEDGE,WC_TREEVIEW,nil,
          WS_VISIBLE or WS_CHILD or TVS_HASLINES or TVS_HASBUTTONS or
          TVS_EDITLABELS,0,0,10,10,wnd,IDC_TREEVIEW,hInstance,nil);
        if(hTreeView = 0) then
          SendMessage(wnd,WM_CLOSE,0,0);

        // Determine the handle to the system image list
        ZeroMemory(@fi,sizeof(TSHFileInfo));
        hSmallImg := HIMAGELIST(SHGetFileInfo('',0,fi,sizeof(fi),
          SHGFI_SYSICONINDEX or SHGFI_SMALLICON));
        if(hSmallImg <> 0) then
          TreeView_SetImageList(hTreeview,hSmallImg,TVSIL_NORMAL);

        // Drive "C:\" scan
        FillTreeView(hTreeview,iCurDrive);
      end;
    WM_DESTROY:
      begin
        FreeTV(hTreeView);
        PostQuitMessage(0);
      end;
    WM_SIZE:
      begin
        MoveWindow(hStatusbar,0,HIWORD(lp),LOWORD(lp),HIWORD(lp),true);
        GetClientRect(hStatusbar,rc);
        i := rc.Bottom - rc.Top;

        GetClientRect(wnd,rc);
        MoveWindow(hTreeView,rc.Left,rc.Top,rc.Right,rc.Bottom-i,true);
      end;
    WM_GETMINMAXINFO:
      begin
        PMinMaxInfo(lp)^.ptMinTrackSize.X := wWidth;
        PMinMaxInfo(lp)^.ptMinTrackSize.Y := wHeight;

        PMinMaxInfo(lp)^.ptMaxTrackSize.x := 800;
        PMinMaxInfo(lp)^.ptMaxTrackSize.y := 600;
      end;
    WM_COMMAND:
      case HIWORD(wp) of
        BN_CLICKED:
          case LOWORD(wp) of
            3..26:
              begin
                iCurDrive := LOWORD(wp);

                // Reset "old" entry
                // (Remove marker from menu)
                for i := 3 to 26 do
                  if(GetMenuState(GetMenu(wnd),i,MF_BYCOMMAND) and
                       MF_CHECKED <> 0) then
                    CheckMenuItem(GetMenu(wnd),i,MF_BYCOMMAND or MF_UNCHECKED);

                // Scan new (selected) drive, ...
                FillTreeView(hTreeview,LOWORD(wp));

                // ... & and highlight menu entry
                CheckMenuItem(GetMenu(wnd),iCurDrive,MF_BYCOMMAND or
                  MF_CHECKED);
              end;
            IDM_EXIT:
              SendMessage(wnd,WM_CLOSE,0,0);
            IDM_LINES:
              CheckMenuItem(GetMenu(wnd),LOWORD(wp),MF_BYCOMMAND or
                fCheckState[SetStyle(hTreeview,TVS_HASLINES) and
                TVS_HASLINES <> 0]);
            IDM_BUTTONS:
              CheckMenuItem(GetMenu(wnd),LOWORD(wp),MF_BYCOMMAND or
                fCheckState[SetStyle(hTreeview,TVS_HASBUTTONS) and
                TVS_HASBUTTONS <> 0]);
            IDM_HOTTRACK:
              CheckMenuItem(GetMenu(wnd),LOWORD(wp),MF_BYCOMMAND or
                fCheckState[SetStyle(hTreeview,TVS_TRACKSELECT or
                TVS_SINGLEEXPAND) and
                (TVS_TRACKSELECT or TVS_SINGLEEXPAND) <> 0]);
            IDM_MOVE,
            IDM_COPY:
              begin
                // BeginUpdate
                SendMessage(hTreeview,WM_SETREDRAW,WPARAM(false),0);

                CopyResult := true; // default
                HitHandle  := TreeView_GetSelection(hTreeview);

                // First check if the node is still scanned.
                // must be
                tv.mask    := TVIF_HANDLE or TVIF_PARAM;
                tv.hItem   := HitHandle;
                TreeView_GetItem(hTreeview,tv);
                ScanTreeViewAgain(hTreeview,TFolderId(tv.lParam),HitHandle);

                // Now copy the selected node, ...
                CopyItems(hTreeview,hOldItem,HitHandle);
                // ... & den alten Knoten entfernen
                if(LOWORD(wp) = IDM_MOVE) then
                  Treeview_DeleteItem(hTreeview,hOldItem);

                // EndUpdate
                SendMessage(hTreeview,WM_SETREDRAW,WPARAM(true),0);

                // Select a new parent item and "expand" it.
                TreeView_SelectItem(hTreeview,HitHandle);
                TreeView_Expand(hTreeView,HitHandle,TVE_EXPAND);
              end;
          end;
      end;
    // Drag & Drop
    WM_NOTIFY:
      with PNMTreeView(lp)^ do
        case hdr.code of
          TVN_ENDLABELEDIT:
            if(PTVDispInfo(lp)^.item.pszText <> '') then
            begin
              tv.hItem      := PTVDispInfo(lp)^.item.hItem;
              tv.mask       := TVIF_TEXT;
              tv.pszText    := buf;
              tv.cchTextMax := sizeof(buf);

              if(TreeView_GetItem(hdr.hwndFrom,tv)) then
              begin
                MessageBox(wnd,pchar(Format('"%s" vs. "%s"',
                  [buf,PTVDispInfo(lp)^.item.pszText])),nil,0);

                Result := 1;
              end;
            end;
          TVN_KEYDOWN:
            if(PTVKeyDown(lp)^.wVKey = VK_F2) then
            begin
              HitHandle := TreeView_GetSelection(hdr.hwndFrom);
              if(HitHandle <> nil) then
              begin
                SetFocus(hdr.hwndFrom);
                TreeView_EditLabel(hdr.hwndFrom,HitHandle);
              end;
            end;
          TVN_BEGINDRAG,
          TVN_BEGINRDRAG:
            begin
              // The treeview should generate the drag image.
              hDragImgList := TreeView_CreateDragImage(hTreeview,
                itemNew.hItem);

              // Save current item handle
              hOldItem := itemNew.hItem;

              // Start drag and drop, and protect Treeview from updates
              ImageList_BeginDrag(hDragImgList,0,0,0);
              ImageList_DragEnter(hTreeview,ptDrag.x,ptDrag.y);

              // Limit mouse notifications to the main window
              SetCapture(wnd);

              // We're in drag mode!
              DragMode := true;
            end;
          // Determine subfolders
          TVN_ITEMEXPANDING:
            ScanTreeViewAgain(hTreeView,TFolderId(itemNew.lParam),
              itemNew.hItem);
          // show current path
          TVN_SELCHANGED:
            begin
{$IFDEF SIMPLE}
              itemNew.mask       := TVIF_TEXT;
              itemNew.pszText    := buf;
              itemNew.cchTextMax := sizeof(buf);
              if(TreeView_GetItem(hdr.hwndFrom,itemNew)) then
                SendMessage(hStatusBar,SB_SETTEXT,SB_SIMPLEID,
                LPARAM(@buf));
{$ELSE}
              tv.mask       := TVIF_PARAM;
              tv.hItem      := itemNew.hItem;
              if(TreeView_GetItem(hdr.hwndFrom,tv)) then
              begin
                fid         := TFolderId(tv.lParam);
                if(fid <> nil) then
                  SendMessage(hStatusBar,SB_SETTEXT,SB_SIMPLEID,
                    LPARAM(pchar(GetDisplayName(fid.Folder,fid.pidl,
                    SHGDN_NORMAL or SHGDN_FORPARSING))));
              end;
{$ENDIF}
            end;
        end;
    WM_MOUSEMOVE:
      if(DragMode) then
      begin
        // Drag image to the current position of the mouse pointer
        // move
        ImageList_DragMove(LOWORD(lp),HIWORD(lp));

        // briefly hide the drag image ...
        ImageList_DragShowNolock(false);

        // find out which item is "under" the mouse pointer
        // lies
        tvhit.pt.x := LOWORD(lp);
        tvhit.pt.y := HIWORD(lp);
        HitHandle  := TreeView_HitTest(hTreeview,tvhit);

        // mark!
        if(HitHandle <> nil) then
          TreeView_SelectDropTarget(hTreeview,HitHandle);

        // and display the dragged image again
        ImageList_DragShowNolock(true);
      end;
    WM_LBUTTONUP, // LEFT MOUSE BUTTON!
    WM_RBUTTONUP: // RIGHT MOUSE KEY!
      if(DragMode) then
      begin
        // Release Treeview for update,
        // & Hide drag image
        ImageList_DragLeave(hTreeview);

        // End drag operation and destroy image list
        ImageList_EndDrag;
        ImageList_Destroy(hDragImgList);

        // Re-release mouse messages,
        // & Reset drag mode
        ReleaseCapture;
        DragMode := false;

        // Select the item that was last under the mouse.
        TreeView_SelectItem(hTreeview,TreeView_GetDropHilite(hTreeview));

        // The old item cannot be the new item.!
        if(hOldItem = TreeView_GetSelection(hTreeview)) then exit;

        // Move entry, ...
        if(uMsg = WM_LBUTTONUP) then
          SendMessage(wnd,WM_COMMAND,MAKEWPARAM(IDM_MOVE,BN_CLICKED),0)
        // ... or copy
        else
        begin
          menu := CreatePopupMenu;
          AppendMenu(menu,MF_STRING,IDM_MOVE,'move');
          AppendMenu(menu,MF_STRING,IDM_COPY,'copy');
          GetCursorPos(p);
          TrackPopupMenu(menu,TPM_RIGHTALIGN,p.X,p.Y,0,wnd,nil);
          DestroyMenu(menu);
        end;
      end;
    else
      Result := DefWindowProc(wnd,uMsg,wp,lp);
  end;
end;


// -- WinMain ------------------------------------------------------------------

const
  szClassname = 'TreeWndClass';
  szAppname   = 'Tree-View Sample';
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
     dwICC:ICC_TREEVIEW_CLASSES or ICC_BAR_CLASSES;);
  hwndMsg  : TMsg;
  aWnd     : HWND;

begin
  if(CoInitializeEx(nil,COINIT_APARTMENTTHREADED) = S_OK) then
  try
    // "Common Controls" initial
    InitCommonControlsEx(icc);

    // Klasse registrieren
    wc.hInstance := hInstance;
    wc.hIcon     := LoadIcon(0,IDI_WINLOGO);
    wc.hCursor   := LoadCursor(0,IDC_ARROW);
    if(RegisterClassEx(wc) = 0) then exit;

    // Create window
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