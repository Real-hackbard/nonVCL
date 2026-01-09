program Listview;

{$R resource.res}

uses
  Windows,
  Messages,
  ShellAPI,
  CommCtrl,
  CommCtrl_Fragment in 'CommCtrl_Fragment.pas',
  MSysUtils in 'MSysUtils.pas';

var
  colArray : array[0..1]of integer = (2,1);


//
// Spalten erzeugen
//
procedure MakeColumns(const hLV: HWND);
var
  lvc        : TLVColumn;
  tileinfo   : TLVTileViewInfo;
begin
  // Text- und cx-Membervariablen sind gültig
  lvc.mask    := LVCF_TEXT or LVCF_WIDTH;
  lvc.pszText := 'File';
  lvc.cx      := 200;
  ListView_InsertColumn(hLV,0,lvc);

  // rechtbündiger Text (Ausrichtung)
  lvc.mask    := lvc.mask or LVCF_FMT;
  lvc.fmt     := LVCFMT_RIGHT;
  lvc.pszText := 'Size';
  lvc.cx      := 150;
  ListView_InsertColumn(hLV,1,lvc);

  // The last column is a normal column again.
  // without any further special features
  lvc.mask    := lvc.mask and not LVCF_FMT;
  lvc.pszText := 'Filetyp';
  lvc.cx      := 100;
  ListView_InsertColumn(hLV,2,lvc);

  if (IsWindowsXP) or (IsWindowsVista) then
  begin
    tileinfo.cbSize  := sizeof(TLVTileViewInfo);
    tileinfo.dwMask  := LVTVIM_COLUMNS;
    tileinfo.dwFlags := LVTVIF_AUTOSIZE;
    tileinfo.cLines  := length(colArray);
    ListView_SetTileViewInfo(hLV,tileinfo);
  end;
end;

//
// Load files from the current directory (NicoDE)
//
procedure BeginUpdate(const wnd: HWND; UpdateState: boolean);
begin
  SendMessage(wnd,WM_SETREDRAW,WPARAM(not UpdateState),0);
end;

procedure GetFiles(const hLV: HWND);
var
  finddata : TWin32FindData;
  hFile    : cardinal;
  Loop     : dword;
  lvi      : TLVItem;
  buf      : array[0..25]of char;
  tile     : TLVTileInfo;
  fi       : TSHFileInfo;
begin
  BeginUpdate(hLV,true);

  hFile  := FindFirstFile('*.*',finddata);
  if(hFile <> INVALID_HANDLE_VALUE) then begin
    Loop := 0;

    repeat
      if(finddata.dwFileAttributes and
        FILE_ATTRIBUTE_DIRECTORY = 0) then
      begin
        ZeroMemory(@fi,sizeof(TSHFileInfo));
        SHGetFileInfo(finddata.cFilename,0,fi,sizeof(TSHFileInfo),
          SHGFI_ICON or SHGFI_SYSICONINDEX or SHGFI_TYPENAME);

        // Text and image are valid
        lvi.mask     := LVIF_TEXT or LVIF_IMAGE;
        // Item-Index
        lvi.iItem    := Loop;
        lvi.iSubItem := 0;
        // Text
        lvi.pszText  := finddata.cFileName;
        // Image
        lvi.iImage   := fi.iIcon;
        ListView_InsertItem(hLV,lvi);

        // File size information
        ZeroMemory(@buf,sizeof(buf));
        wvsprintf (buf,'%u B',pchar(@finddata.nFileSizeLow));
        lvi.mask     := LVIF_TEXT;
        lvi.iSubItem := 1;
        lvi.pszText  := buf;
        ListView_SetItem(hLV,lvi);

        // Filetyp
        lvi.mask     := LVIF_TEXT;
        lvi.iSubItem := 2;
        lvi.pszText  := fi.szTypeName;
        ListView_SetItem(hLV,lvi);

        // Information about tile view
        if (IsWindowsXP) or (IsWindowsVista) then
        begin
          tile.cbSize    := sizeof(TLVTileInfo);
          tile.iItem     := Loop;                 // Item-Nr.
          tile.cColumns  := length(colArray);     // Columns to display
          tile.puColumns := @colArray[0];         // Column index array
          ListView_SetTileInfo(hLV,tile);
        end;

        // "Loop" increase
        Inc(Loop);
      end;
    until(not FindNextFile(hFile,finddata));

    FindClose(hFile);
  end;

  BeginUpdate(hLV,false);
end;

//
// Show currently selected item
//
procedure ShowCurrentFocus(const hLV: HWND);
var
  idx : integer;
  buf : array [0..255] of Char;
begin
  idx := ListView_GetNextItem(hLV,-1,LVNI_FOCUSED);

  if(idx > -1) then begin
    ZeroMemory(@buf,sizeof(buf));
    ListView_GetItemText(hLV,idx,0,buf,sizeof(buf));

    if(buf[0] <> #0) then
      MessageBox(hLV,buf,'Ihre Auswahl',0);
  end;
end;

//
// Change the view of the list view (PSDK, + Win code)
//
procedure SetView(const hLV: HWND; dwView: dword);
var
  dwStyle : dword;
begin
  // Under Windows a new command is used,
  // which also includes the tile view (tiles)
  // can be switched on
  if (IsWindowsXP) or (IsWindowsVista) then
  begin
    case dwView of
      LVS_ICON:
        ListView_SetView(hLV,LV_VIEW_ICON);
      LVS_SMALLICON:
        ListView_SetView(hLV,LV_VIEW_SMALLICON);
      LVS_LIST:
        ListView_SetView(hLV,LV_VIEW_LIST);
      LVS_REPORT:
        ListView_SetView(hLV,LV_VIEW_DETAILS);
      666:
        ListView_SetView(hLV,LV_VIEW_TILE);
    end;
  // No Windows -> then follow the known method
  // of the code that is translated from PSDK to Delphi
  // wurde
  end else begin
    dwStyle := GetWindowLong(hLV,GWL_STYLE);

    if(dwStyle and LVS_TYPEMASK <> dwView) then
      SetWindowLong(hLV,GWL_STYLE,
      (dwStyle and not LVS_TYPEMASK) or dwView);
  end;
end;

//
// Select all items, or reverse the selection.
//
procedure MarkAllItems(const hLV: HWND; fTurnSelection: boolean);
const
  fStateState : array[boolean]of cardinal =
    (0,LVIS_SELECTED);
var
  i           : integer;
  uRes        : UINT;
begin
  for i := 0 to ListView_GetItemCount(hLV) - 1 do begin
    uRes := ListView_GetItemState(hLV,i,LVIS_SELECTED);

    ListView_SetItemState(hLV,i,
      fStateState[(uRes and LVIS_SELECTED = 0) or
      (not fTurnSelection)],LVIS_SELECTED);
  end;
end;

procedure RebuildGroups(const hLV: HWND; iSubItem: integer;
  fEnableView: boolean);
const
  MIN_GROUP_ID = 2000;
var
  i            : integer;
  fsize        : integer;
  fFound       : boolean;
  buf          : string;
  wbuf         : array[0..MAX_PATH]of widechar;
  gi           : integer;
  group        : TLVGroup;
  lvi          : TLVItem60;
begin
  if(not IsWindowsXP) and (not IsWindowsVista) then exit;
  if(ListView_GetItemCount(hLV) = 0) then exit;

  // remove all existing groups
  ListView_RemoveAllGroups(hLV);

  for i := 0 to ListView_GetItemCount(hLV) - 1 do begin
    // Read the item text from the respective column
    SetLength(buf,MAX_PATH); ZeroMemory(@buf[1],MAX_PATH);
    ListView_GetItemText(hLV,i,iSubItem,@buf[1],MAX_PATH);

    // Is there anything to do?
    if(buf <> '') then begin
      fFound := false;

      // What should the groups look like?
      ZeroMemory(@wbuf,sizeof(wbuf));
      case iSubItem of
        // Grouping by file size;
        // Read the size and form six groups
        // (The thresholds can be adjusted to suit your own taste!)
        1: begin
          if(pos(#32,buf) > 0) then delete(buf,pos(#32,buf),length(buf));
          fsize := StrToIntDef(buf,0);

          // Thresholds:
          // 0 < 35k < 130k < 1meg < 10meg < ...
          if(fsize = 0) then lstrcpyW(wbuf,'Equal to zero')
            else if(fsize < 35 * 1024) then lstrcpyW(wbuf,'Tiny')
              else if(fsize < 130 * 1024) then lstrcpyW(wbuf,'Small')
                else if(fsize < 1024 * 1024) then lstrcpyW(wbuf,'Middle')
                  else if(fsize < (10 * 1024) * 1024) then lstrcpyW(wbuf,'Big')
                    else lstrcpyW(wbuf,'Very Big');
        end;

        // Grouping by file type;
        // Copy type name
        2: lstrcpyW(wbuf,pwidechar(widestring(buf)));

        // Grouping by file name;
        // Allow only the first character (A, B, C ...)
        else begin
          SetLength(buf,1);
          buf[1] := UPCASE(buf[1]);

          if(buf[1] in['A'..'Z']) then lstrcpyW(wbuf,pwidechar(widestring(buf)))
            else lstrcpyW(wbuf,'Other');
        end;
      end;

      // Check existing groups to see if the name already exists
      // exists!
      gi := 0;
      while(true) do begin
        ZeroMemory(@group,sizeof(TLVGroup));
        group.cbSize := sizeof(TLVGroup);
        group.mask   := LVGF_HEADER;

        // upps!
        if(ListView_GetGroupInfo(hLV,
          MIN_GROUP_ID+gi,group) = -1) then break;

        // Does the name already exist?
        if(lstrcmpiW(wbuf,group.pszHeader) = 0) then begin
          fFound := true;
          break;
        end;

        inc(gi);
      end;

      // Name does not yet exist; create group
      if(not fFound) then begin
        ZeroMemory(@group,sizeof(TLVGroup));

        group.cbSize    := sizeof(TLVGroup);
        group.mask      := LVGF_HEADER or LVGF_FOOTER or LVGF_GROUPID;
        group.iGroupId  := MIN_GROUP_ID + gi;
        group.pszHeader := wbuf;
        group.cchHeader := lstrlenW(wbuf);
        group.uAlign    := LVGA_HEADER_CENTER;

        ListView_InsertGroup(hLV,-1,group);
      end;

      // Add the item to the group now!
      ZeroMemory(@lvi,sizeof(lvi));
      lvi.mask     := LVIF_GROUPID;
      lvi.iItem    := i;
      lvi.iGroupId := MIN_GROUP_ID + gi;
      SendMessage(hLV,LVM_SETITEM,0,LPARAM(@lvi));
    end;
  end;

  // Should the group view be activated?
  ListView_EnableGroupView(hLV,fEnableView);
end;

var
  hLV       : HWND;
  SortOrder : byte = 0;

//
// Group sorting
//
function CompareGroup(lp1, lp2: LPARAM; pv: pointer): integer; stdcall;
begin
  // Because the entries are _BEFORE_ the grouping of the selection
  // The groups will be sorted accordingly.
  // generated in an ordered sequence.
  // This makes sorting work perfectly, because you only need to...
  // needs to compare the IDs of the groups.
  if(SortOrder = 0) then begin
    if(lp1 < lp2) then Result := -1
      else if(lp1 > lp2) then Result := 1
        else Result := 0;
  end else begin
    if(lp2 < lp1) then Result := -1
      else if(lp2 > lp1) then Result := 1
        else Result := 0;
  end;
  // "Life is good!"
  //:o)
end;

function CompareFunc(lp1, lp2, SubItem: LPARAM): integer; stdcall;
var
  buf1,
  buf2   : string;
  a,
  b      : integer;
begin
  SetLength(buf1,MAX_PATH); ZeroMemory(@buf1[1],MAX_PATH);
  SetLength(buf2,MAX_PATH); ZeroMemory(@buf2[2],MAX_PATH);
  ListView_GetItemText(hLV,lp1,SubItem,@buf1[1],MAX_PATH);
  ListView_GetItemText(hLV,lp2,SubItem,@buf2[1],MAX_PATH);

  case SubItem of
    // File size
    1: begin
         // Remove everything after the space (e.g. "12345 B")
         if(pos(#32,buf1) > 0) then
           delete(buf1,pos(#32,buf1),length(buf1));
         if(pos(#32,buf2) > 0) then
           delete(buf2,pos(#32,buf2),length(buf2));

         if(SortOrder = 1) then begin
           b := StrToIntDef(buf1,0);
           a := StrToIntDef(buf2,0);
         end else begin
           a := StrToIntDef(buf1,0);
           b := StrToIntDef(buf2,0);
         end;

         if(a > b) then Result := 1
           else if(a < b) then Result := -1
             else Result := 0;
       end
    // Name or type
    else begin
      if(SortOrder = 1) then Result := lstrcmpi(@buf2[1],@buf1[1])
        else Result := lstrcmpi(@buf1[1],@buf2[1]);
    end;
  end;
end;

procedure UpdateLParam(const hLV: HWND);
var
  lvi : TLVItem;
  i   : integer;
begin
  lvi.mask     := LVIF_PARAM;
  lvi.iSubItem := 0;

  for i        := 0 to ListView_GetItemCount(hLV) - 1 do begin
    lvi.iItem  := i;
    lvi.lParam := i;
    SendMessage(hLV,LVM_SETITEM,0,LPARAM(@lvi));
  end;
end;

const
  fSortBmp      : array[boolean]of integer =
    (HDF_SORTDOWN,HDF_SORTUP);
  BMP_SORTBMP   = 300;
var
  hHeader       : HWND;
  iHeaderVer    : integer = 0;

procedure SetHeader_SortBmp(const hwndHeader: HWND; iIdx: integer);
var
  hi            : THDItem;
  buf           : array[0..MAX_PATH]of char;
begin
  // Determine current header data
  hi.Mask       := HDI_FORMAT or HDI_IMAGE or HDI_ORDER or HDI_TEXT or
    HDI_WIDTH;
  hi.pszText    := buf;
  hi.cchTextMax := sizeof(buf);
  Header_GetItem(hwndHeader,iIdx,hi);

  // Add sort bitmap
  hi.fmt        := hi.fmt or HDF_BITMAP_ON_RIGHT;
  if(iHeaderVer >= 6) then hi.fmt := hi.fmt or fSortBmp[SortOrder=0]
    else begin
      hi.fmt    := hi.fmt or HDF_IMAGE;
      hi.iImage := SortOrder;
    end;
  Header_SetItem(hwndHeader,iIdx,hi);
end;

procedure SetHeader_RemoveBmp(const hwndHeader: HWND; iIdx: integer);
var
  hi            : THDItem;
  buf           : array[0..MAX_PATH]of char;
begin
  // Retrieve current header data
  hi.Mask       := HDI_BITMAP or HDI_FORMAT or HDI_IMAGE or HDI_ORDER or
    HDI_TEXT or HDI_WIDTH;
  hi.pszText    := buf;
  hi.cchTextMax := sizeof(buf);
  Header_GetItem(hwndHeader,iIdx,hi);

  // Remove Bitmap flags
  hi.fmt        := hi.fmt and not fSortBmp[true] and not fSortBmp[false]
    and not HDF_BITMAP_ON_RIGHT and not HDF_IMAGE;
  Header_SetItem(hwndHeader,iIdx,hi);
end;

//
// "WndProc"
//
const
  wWidth          = 500;
  wHeight         = 350;

  IDC_LV          = 100;
  IDC_TOOLBAR	  = 200;
  IDM_ICONS       = 101;
  IDM_SMICONS     = 102;
  IDM_LIST        = 103;
  IDM_REPORT      = 104;
  IDM_TILES       = 150;
  IDM_NAMESORT    = 151;
  IDM_SIZESORT    = 152;
  IDM_TYPESORT    = 153;
  IDM_GROUP       = 170;
  IDM_EDITLABEL   = 105;
  IDM_SELALL      = 106;
  IDM_TURNSEL     = 107;

var
  tbButtons       : array[0..7] of TTBButton =
    ((iBitmap:VIEW_LARGEICONS;
      idCommand:IDM_ICONS;
      fsState:TBSTATE_ENABLED;
      fsStyle:BTNS_CHECKGROUP;
      dwData:0;
      iString:0;),
     (iBitmap:VIEW_SMALLICONS;
      idCommand:IDM_SMICONS;
      fsState:TBSTATE_ENABLED;
      fsStyle:BTNS_CHECKGROUP;
      dwData:0;
      iString:0;),
     (iBitmap:VIEW_LIST;
      idCommand:IDM_LIST;
      fsState:TBSTATE_ENABLED;
      fsStyle:BTNS_CHECKGROUP;
      dwData:0;
      iString:0;),
     (iBitmap:VIEW_DETAILS;
      idCommand:IDM_REPORT;
      fsState:TBSTATE_ENABLED or TBSTATE_CHECKED;
      fsStyle:BTNS_CHECKGROUP;
      dwData:0;
      iString:0;),
     (iBitmap:I_IMAGENONE;
      idCommand:0;
      fsState:TBSTATE_ENABLED;
      fsStyle:BTNS_SEP;
      dwData:0;
      iString:0;),
     (iBitmap:VIEW_SORTNAME;
      idCommand:IDM_NAMESORT;
      fsState:TBSTATE_ENABLED;
      fsStyle:BTNS_BUTTON;
      dwData:0;
      iString:0;),
     (iBitmap:VIEW_SORTSIZE;
      idCommand:IDM_SIZESORT;
      fsState:TBSTATE_ENABLED;
      fsStyle:BTNS_BUTTON;
      dwData:0;
      iString:0;),
     (iBitmap:VIEW_SORTTYPE;
      idCommand:IDM_TYPESORT;
      fsState:TBSTATE_ENABLED;
      fsStyle:BTNS_BUTTON;
      dwData:0;
      iString:0;));
  hToolbar	  : HWND;
  hSortImg,
  hImgSm,
  hImgBig         : HIMAGELIST;
  LastCol         : integer = 0;


function WndProc(wnd: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM): LRESULT;
  stdcall;
const
  fChkArray : array[boolean]of cardinal =
    (MF_UNCHECKED,MF_CHECKED);
var
  i         : integer;
  buf       : array[0..MAX_PATH]of char;
  fi        : TSHFileInfo;
  bBmp      : TBAddBitmap;
  r	    : TRect;
begin
  Result := 0;

  case uMsg of
    WM_CREATE:
      begin
      	// Toolbar create
        hToolBar := CreateWindowEx(0,TOOLBARCLASSNAME,nil,WS_CHILD or
          WS_VISIBLE or CCS_NODIVIDER or TBSTYLE_FLAT or
          TBSTYLE_TOOLTIPS,0,0,0,0,wnd,IDC_TOOLBAR,hInstance,nil);

        // Load and assign system bitmaps
	bBmp.hInst := HINST_COMMCTRL;
      	bBmp.nID   := IDB_VIEW_SMALL_COLOR;
      	SendMessage(hToolbar,TB_ADDBITMAP,0,LPARAM(@bBmp));

        // Assign toolbar buttons
        SendMessage(hToolBar,TB_BUTTONSTRUCTSIZE,sizeof(TTBBUTTON),0);
        SendMessage(hToolBar,TB_ADDBUTTONS,length(tbButtons),
          LPARAM(@tbButtons));

        // Listview create
        hLV     := CreateWindowEx(WS_EX_CLIENTEDGE,WC_LISTVIEW,nil,
          WS_VISIBLE or WS_CHILD or LVS_REPORT or LVS_EDITLABELS or
          LVS_SHOWSELALWAYS or LVS_SHAREIMAGELISTS,0,0,100,100,wnd,
          IDC_LV,hInstance,nil);

        // Set advanced styles
        SendMessage(hLV,LVM_SETEXTENDEDLISTVIEWSTYLE,0,
          LVS_EX_HEADERDRAGDROP or LVS_EX_FULLROWSELECT);

        // Handle to the system image list with the small icons
        ZeroMemory(@fi,sizeof(TSHFileInfo));
        hImgSm  := HIMAGELIST(SHGetFileInfo('',0,fi,sizeof(fi),
          SHGFI_SYSICONINDEX or SHGFI_SMALLICON));
        if(hImgSm <> 0) then
          ListView_SetImageList(hLV,hImgSm,LVSIL_SMALL);

        // Handle to the system image list with the large icons
        ZeroMemory(@fi,sizeof(TSHFileInfo));
        hImgBig := HIMAGELIST(SHGetFileInfo('',0,fi,sizeof(fi),
          SHGFI_SYSICONINDEX or SHGFI_ICON));
        if(hImgBig <> 0) then
          ListView_SetImageList(hLV,hImgBig,LVSIL_NORMAL);

        // Determine the version of the list view
        hHeader    := ListView_GetHeader(hLV);
        iHeaderVer := SendMessage(hHeader,CCM_GETVERSION,0,0);

        // If "iLVVer < 6", then ImageList for sort bitmaps
        // load
        if(iHeaderVer < 6) then begin
          hSortImg := ImageList_LoadBitmap(hInstance,
            MAKEINTRESOURCE(BMP_SORTBMP),7,1,$00c0c0c0);
          Header_SetImageList(hHeader,hSortImg);
        end;

        // Create columns
        MakeColumns(hLV);

        // Mark sorting direction
        SetHeader_SortBmp(hHeader,0);

        // Fill list view
        GetFiles(hLV);

        // Pre-sorting, & forming groups
        UpdateLParam(hLV);
        ListView_SortItems(hLV,@CompareFunc,0);
        RebuildGroups(hLV,0,false);

        SortOrder := 1;

        // highlight current column
        if(IsWindowsXP) or (IsWindowsVista) then ListView_SetSelectedColumn(hLV,0);

        // Set current sorting and view in the menu
        CheckMenuRadioItem(GetMenu(wnd),IDM_NAMESORT,IDM_TYPESORT,
          IDM_NAMESORT,MF_BYCOMMAND);
        CheckMenuRadioItem(GetMenu(wnd),IDM_ICONS,IDM_TILES,
          IDM_REPORT,MF_BYCOMMAND);

        // If using Windows, then enable Tile View and groups.
        if (IsWindowsXP) or (IsWindowsVista) then
        begin
          EnableMenuItem(GetMenu(wnd),IDM_TILES,MF_BYCOMMAND);
          EnableMenuItem(GetMenu(wnd),IDM_GROUP,MF_BYCOMMAND);
        // or remove the menu items
        end
        else begin
          DeleteMenu(GetMenu(wnd),IDM_TILES,MF_BYCOMMAND);
          DeleteMenu(GetMenu(wnd),171,MF_BYCOMMAND);       // SEPARATOR
          DeleteMenu(GetMenu(wnd),IDM_GROUP,MF_BYCOMMAND);
        end;
      end;
    WM_DESTROY:
      begin
        // remove all groups
        ListView_RemoveAllGroups(hLV);

        // Remove sorting image list (if necessary)
        if(iHeaderVer < 6) then ImageList_Destroy(hSortImg);

        PostQuitMessage(0);
      end;
    WM_SIZE:
      begin
        // Determine the toolbar height, ...
        GetWindowRect(hToolbar,r);

        // ... & Adjust the size of the list view
        MoveWindow(hLV,0,r.Bottom - r.Top,LOWORD(lp),
          HIWORD(lp) - (r.Bottom - r.Top),true);
      end;
    WM_COMMAND:
      if(HIWORD(wp) = BN_CLICKED) then
        case LOWORD(wp) of
          IDM_ICONS,
          IDM_SMICONS,
          IDM_LIST,
          IDM_TILES,
          IDM_REPORT:
            begin
              case LOWORD(wp) of
                IDM_ICONS:
                  SetView(hLV,LVS_ICON);
                IDM_SMICONS:
                  SetView(hLV,LVS_SMALLICON);
                IDM_LIST:
                  SetView(hLV,LVS_LIST);
                IDM_TILES:
                  if (IsWindowsXP) or (IsWindowsVista) then SetView(hLV,666); // ;o)
                IDM_REPORT:
                  SetView(hLV,LVS_REPORT);
              end;

              // Set new view in menu
              CheckMenuRadioItem(GetMenu(wnd),IDM_ICONS,IDM_TILES,
                LOWORD(wp),MF_BYCOMMAND);
            end;
          IDM_EDITLABEL:
            begin
              i := ListView_GetNextItem(hLV,-1,LVNI_FOCUSED);
              if(i > -1) then begin
                SetFocus(hLV);
                ListView_EditLabel(hLV,i);
              end;
            end;
          IDM_SELALL,
          IDM_TURNSEL:
            MarkAllItems(hLV,wp = IDM_TURNSEL);
          IDM_NAMESORT,
          IDM_TYPESORT,
          IDM_SIZESORT:
            begin
              // If columns are different, then in ascending order.
              // sort
              if(LastCol <> LOWORD(wp) - IDM_NAMESORT) then
                SortOrder := 0;

              // highlight current column
              if (IsWindowsXP) or (IsWindowsVista) then ListView_SetSelectedColumn(hLV,
                LOWORD(wp) - IDM_NAMESORT);

              // Customize menu
              CheckMenuRadioItem(GetMenu(wnd),IDM_NAMESORT,IDM_TYPESORT,
                LOWORD(wp),MF_BYCOMMAND);

              // Sort
              UpdateLParam(hLV);
              ListView_SortItems(hLV,@CompareFunc,
                LOWORD(wp) - IDM_NAMESORT);

              // Recreate groups when the column
              // geändert hat
              if(LastCol <> LOWORD(wp) - IDM_NAMESORT) then
                RebuildGroups(hLV,LOWORD(wp) - IDM_NAMESORT,
                ListView_IsGroupViewEnabled(hLV));

              // Sort groups
              ListView_SortGroups(hLV,@CompareGroup,nil);

              // Update header bitmap (sorting)
              SetHeader_RemoveBmp(hHeader,LastCol);
              SetHeader_SortBmp  (hHeader,LOWORD(wp)-IDM_NAMESORT);

              // Reverse sort order
              SortOrder := 1 - SortOrder;

              // remember current column
              LastCol   := LOWORD(wp) - IDM_NAMESORT;
            end;
          IDM_GROUP:
            begin
              // Enable or disable group view
              ListView_EnableGroupView(hLV,
                not ListView_IsGroupViewEnabled(hLV));

              // Menu item when group view is active
              // mark
              CheckMenuItem(GetMenu(wnd),IDM_GROUP,MF_BYCOMMAND or
                fChkArray[ListView_IsGroupViewEnabled(hLV)]);
            end;
        end;
    WM_NOTIFY:
      with PNMHdr(lp)^ do
        if(code = TTN_NEEDTEXT) then begin
          case PToolTipText(lp)^.hdr.idFrom of
            IDM_ICONS:
              PToolTipText(lp)^.lpszText := 'Big symbols';
            IDM_SMICONS:
              PToolTipText(lp)^.lpszText := 'Small symbols';
            IDM_LIST:
              PToolTipText(lp)^.lpszText := 'List';
            IDM_REPORT:
              PToolTipText(lp)^.lpszText := 'Details';
            IDM_NAMESORT:
              PToolTipText(lp)^.lpszText := 'sort by name';
            IDM_SIZESORT:
              PToolTipText(lp)^.lpszText := 'sort by size';
            IDM_TYPESORT:
              PToolTipText(lp)^.lpszText := 'sort by type';
          end;
        end else if(hwndFrom = hLV) then
          case code of
            NM_DBLCLK:
              // Double-click on an entry
              ShowCurrentFocus(hwndFrom);
            NM_CLICK,
            LVN_ITEMCHANGED:
              if(ListView_GetNextItem(hwndFrom,-1,LVNI_FOCUSED) <> -1) then
                EnableMenuItem(GetMenu(wnd),IDM_EDITLABEL,MF_BYCOMMAND);
            LVN_ENDLABELEDIT:
              if(PLVDispInfo(lp)^.item.pszText <> '') then begin
                i := ListView_GetNextItem(hwndFrom,-1,LVNI_FOCUSED);
                if(i > -1) then begin
                  ZeroMemory(@buf,sizeof(buf));
                  ListView_GetItemText(hwndFrom,i,0,buf,sizeof(buf));

                  // Before vs. After
                  if(MessageBox(0,pchar(Format('Do you want "%s" in "%s" change?',
                    [buf,PLVDispInfo(lp)^.item.pszText])),'???',
                    MB_YESNO or MB_ICONQUESTION) = IDYES) then

                  // Change label name
                  Result := 1;
                end;
              end;
            LVN_KEYDOWN:
              // Trigger edit mode manually
              if(PLVKeyDown(lp)^.wVKey = VK_F2) then
                SendMessage(wnd,WM_COMMAND,MAKEWPARAM(IDM_EDITLABEL,
                BN_CLICKED),0);
            LVN_COLUMNCLICK:
              // The sorting is done by a simulated
              // Selection in menu (name, size, type) triggered
              SendMessage(wnd,WM_COMMAND,
                MAKEWPARAM(PNMListView(lp)^.iSubItem + IDM_NAMESORT,
                BN_CLICKED),0);
          end;
    else
      Result := DefWindowProc(wnd,uMsg,wp,lp);
  end;
end;

//
// WinMain
//
const
  szClassName     = 'LVWndClass';
  szAppName       = 'List View - nonVCL';
var
  msg   : TMsg;
  iccex : TInitCommonControlsEx =
    (dwSize:sizeof(TInitCommonControlsEx);
     dwICC:ICC_LISTVIEW_CLASSES or ICC_BAR_CLASSES;);
  wc    : TWndClassEx =
    (cbSize: SizeOf(TWndClassEx);
     Style: CS_HREDRAW or CS_VREDRAW;
     lpfnWndProc:@WndProc;
     cbClsExtra:0;
     cbWndExtra:0;
     lpszMenuName:MAKEINTRESOURCE(100);
     lpszClassName:szClassName;
     hIconSm:0;);
begin
  InitCommonControlsEx(iccex);

  // Register window class, & create window
  wc.hInstance     := hInstance;
  wc.hbrBackground := GetSysColorBrush(COLOR_3DFACE);
  wc.hIcon         := LoadIcon(0,IDI_APPLICATION);
  wc.hCursor       := LoadCursor(0,IDC_ARROW);
  if(RegisterClassEx(wc) = 0) then exit;

  if(CreateWindowEx(0,szClassName,szAppName,WS_OVERLAPPEDWINDOW or
    WS_VISIBLE,integer(CW_USEDEFAULT),integer(CW_USEDEFAULT),
    wWidth,wHeight,0,0,hInstance,nil) = 0) then exit;

  while(GetMessage(msg,0,0,0)) do begin
    TranslateMessage(msg);
    DispatchMessage(msg);
  end;
end.
