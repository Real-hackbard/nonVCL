program UIS;

{.$DEFINE GRIDLINES}

uses
  Windows,
  Messages,
  CommCtrl,
  CommCtrl_Fragment in 'CommCtrl_Fragment.pas',
  MSysUtils in 'MSysUtils.pas';


{$R UIS.res}

//
// progress dialog
//
const
  IDC_ACTIONLABEL = 110;
  IDC_ACTION      = 120;
  IDC_PROGRESSBAR = 130;

function progressdlgproc(hwndDlg: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM):
  bool; stdcall;
begin
  Result := true;

  case uMsg of
    WM_INITDIALOG:
      SendDlgItemMessage(hwndDlg,IDC_PROGRESSBAR,PBM_SETPOS,0,0);
    WM_CLOSE:
      PostQuitMessage(0);
    else
      Result := false;
  end;
end;

//
// input dialog
//
const
  IDC_DISPNAME  = 210;
  IDC_QUIETNAME = 220;
  IDC_OKBTN     = 230;
  IDC_CANCELBTN = 240;
var
  fChanged      : boolean = false;

function inputdlgproc(hwndDlg: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM):
  bool; stdcall;
begin
  Result := true;

  case uMsg of
    WM_COMMAND:
      if(wp = IDCANCEL) then SendMessage(hwndDlg,WM_CLOSE,0,0)
        else case HIWORD(wp) of
        BN_CLICKED:
          case LOWORD(wp) of
            IDC_OKBTN:
              begin
                fChanged := true;
                SendMessage(hwndDlg,WM_CLOSE,0,0);
              end;
            IDC_CANCELBTN:
              SendMessage(hwndDlg,WM_CLOSE,0,0);
          end;
      end;
    WM_CLOSE:
      PostQuitMessage(0);
    else
      Result := false;
  end;
end;


//
// launch dialog and wait (function taken from the Jedis)
//
function WinExec32AndWait(const Cmd: string; const CmdShow: Integer): Cardinal;
var
  si: TStartupInfo;
  pi: TProcessInformation;
begin
  Result := Cardinal($FFFFFFFF);

  fillchar(si,sizeof(TStartupInfo),#0);
  si.cb := SizeOf(TStartupInfo);
  si.dwFlags := STARTF_USESHOWWINDOW;
  si.wShowWindow := CmdShow;

  if(CreateProcess(nil,pchar(Cmd),nil,nil,false,NORMAL_PRIORITY_CLASS,
    nil,nil,si,pi)) then
  begin
    WaitForInputIdle(pi.hProcess,INFINITE);

    if(WaitForSingleObject(pi.hProcess, INFINITE) = WAIT_OBJECT_0) then begin
      {$IFDEF VER110}
      if not GetExitCodeProcess(pi.hProcess, Integer(Result)) then
      {$ELSE}
      if not GetExitCodeProcess(pi.hProcess, Result) then
      {$ENDIF VER110}
        Result := Cardinal($FFFFFFFF);
    end;

    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
  end;
end;


//
// create Listview columns
//
const
  IDC_EDITBTN      = 100;
  IDC_DELBTN       = 101;
  IDC_DEINSTALLBTN = 102;
  IDC_REFRESHBTN   = 103;
var
  hToolbar,
  hListview,
  hStatusbar       : HWND;

type
  TColumns =
    record
      mask    : cardinal;
      fmt     : integer;
      pszText : pchar;
      cx      : integer;
    end;
var
  Columns : array[1..6]of TColumns =
    ((mask:LVCF_TEXT or LVCF_WIDTH;
      fmt:LVCFMT_LEFT;
      pszText:'Registry-Key';
      cx:100;),
     (mask:LVCF_FMT;
      fmt:LVCFMT_LEFT;
      pszText:'Displayname';
      cx:110;),
     (mask:LVCF_FMT;
      fmt:LVCFMT_LEFT;
      pszText:'Uninstall';
      cx:110;),
     (mask:LVCF_FMT;
      fmt:LVCFMT_LEFT;
      pszText:'QuietDisplayname';
      cx:110;),
     (mask:LVCF_FMT;
      fmt:LVCFMT_LEFT;
      pszText:'QuietUninstall';
      cx:110;),
     (mask:LVCF_FMT;
      fmt:LVCFMT_LEFT;
      pszText:'leer';
      cx:60;));

procedure MakeLVColumns(wnd: HWND);
var
  i   : integer;
  lvc : TLVColumn;
begin
  ZeroMemory(@lvc,sizeof(TLVColumn));

  for i := 1 to length(Columns) do begin
    lvc.mask    := lvc.mask or Columns[i].mask;
    lvc.fmt     := Columns[i].fmt;
    lvc.pszText := Columns[i].pszText;
    lvc.cx      := Columns[i].cx;

    ListView_InsertColumn(wnd,i-1,lvc);
  end;
end;


//
// load Registry keys
//
procedure BeginUpdate(const wnd: HWND; UpdateState: boolean);
begin
  SendMessage(wnd,WM_SETREDRAW,WPARAM(not UpdateState),0);
end;

const
  GrammarEntry : array[boolean]of string = ('Einträge','Eintrag');
  szUnInst     = 'Software\Microsoft\Windows\CurrentVersion\Uninstall';
  szUnknown    = '[unbekannt]';
  szNotFound   = '[nicht gefunden]';
var
  buffer       : array[0..MAX_PATH]of char;

function Reg_ReadString(const RootKey: HKEY; const RegVal: string): string;
var
  lpType,
  cbData   : DWORD;
begin
  Result   := '';

  // no assigned key
  if(RootKey = 0) then exit;

  // "ValueExists"?
  lpType := REG_NONE;
  cbData := 0;

  if(RegQueryValueEx(RootKey,@RegVal[1],nil,@lpType,nil,@cbData) =
       ERROR_SUCCESS) and
    (lpType in[REG_SZ,REG_EXPAND_SZ]) and
    (cbData > 0) then
  begin
    SetLength(Result,cbData);
    if(RegQueryValueEx(RootKey,@RegVal[1],nil,nil,
      @Result[1],@cbData) = ERROR_SUCCESS) then SetLength(Result,cbData-1)
    else Result := '';
  end;
end;

procedure LoadRegKeys;
const
  EmptyKey     : array[boolean]of string = ('no','yes');
var
  rgHandle,
  ukey         : HKEY;
  dwLen        : dword;
  retcode,
  i            : integer;
  count,
  sKeys,
  sValues      : dword;
  li           : TLVItem;
  s            : string;
  dlg          : HWND;
  pBuf         : pchar;
  pBufLen      : dword;
label
  Stop;
begin
  // clear all items
  SendMessage(hStatusbar,SB_SETTEXT,0,LPARAM(nil));
  SendMessage(hStatusbar,SB_SETTEXT,1,LPARAM(nil));

  Listview_DeleteAllItems(hListview);
  UpdateWindow(hListview);
  BeginUpdate(hListview,true);


  dlg    := CreateDialog(hInstance,MAKEINTRESOURCE(100),0,@progressdlgproc);
  buffer := 'initial ...';
  SetWindowText(GetDlgItem(dlg,IDC_ACTIONLABEL),buffer);

  // open Registry, & search all installed apps
  if(RegOpenKeyEx(HKEY_LOCAL_MACHINE,@szUnInst[1],0,
    KEY_READ,rgHandle) = ERROR_SUCCESS) then
  try
    // get number of keys
    if(RegQueryInfoKey(rgHandle,nil,nil,nil,@count,@pBufLen,nil,
      nil,nil,nil,nil,nil) <> ERROR_SUCCESS) or
      (count = 0) then goto Stop;

    GetMem(pBuf,pBufLen+1);
    try
      i := 0;

      while(true) do begin
        ZeroMemory(pBuf,pBufLen+1);
        dwLen   := pBufLen+1;
        retcode := RegEnumKeyEx(rgHandle,i,pBuf,dwLen,nil,nil,nil,nil);

        if(retcode = ERROR_SUCCESS) and
          (RegOpenKeyEx(rgHandle,pBuf,0,KEY_READ,ukey) = ERROR_SUCCESS) then
        try
          // update Progress info
          SetWindowText(GetDlgItem(dlg,IDC_ACTION),pBuf);

          // show internal name
          li.mask     := LVIF_TEXT;
          li.iItem    := i;
          li.iSubItem := 0;
          li.pszText  := pBuf;
          SendMessage(hListview,LVM_INSERTITEM,0,LPARAM(@li));

          // show "DisplayName"
          s                 := Reg_ReadString(ukey,'DisplayName');
          if(s = '') then s := szUnknown;
          li.iSubItem       := 1;
          li.pszText        := @s[1];
          SendMessage(hListview,LVM_SETITEM,0,LPARAM(@li));

          // show "UninstallString"
          s                 := Reg_ReadString(ukey,'UninstallString');
          if(s = '') then s := szNotFound;
          li.iSubItem       := 2;
          li.pszText        := @s[1];
          SendMessage(hListview,LVM_SETITEM,0,LPARAM(@li));

          // show "QuietDisplayName"
          s                 := Reg_ReadString(ukey,'QuietDisplayName');
          if(s = '') then s := szUnknown;
          li.iSubItem       := 3;
          li.pszText        := @s[1];
          SendMessage(hListview,LVM_SETITEM,0,LPARAM(@li));

          // show "QuietUninstallString"
          s                 := Reg_ReadString(ukey,'QuietUninstallString');
          if(s = '') then s := szNotFound;
          li.iSubItem       := 4;
          li.pszText        := @s[1];
          SendMessage(hListview,LVM_SETITEM,0,LPARAM(@li));

          // is this an empty key?
          RegQueryInfoKey(ukey,nil,nil,nil,@sKeys,nil,nil,@sValues,
            nil,nil,nil,nil);
          li.iSubItem       := 5;
          li.pszText        := @EmptyKey[(sKeys = 0) and (sValues = 0)][1];
          SendMessage(hListview,LVM_SETITEM,0,LPARAM(@li));

          // update progressbar
          SendDlgItemMessage(dlg,IDC_PROGRESSBAR,PBM_SETPOS,
            MulDiv(i,100,count),0);
          UpdateWindow(dlg);

          inc(i);
        finally
          RegCloseKey(ukey);
        end else break;
      end;
    finally
      FreeMem(pBuf,pBufLen+1);
    end;

Stop:
  finally
    RegCloseKey(rgHandle);
  end;

  // update statusbar
  i := ListView_GetItemCount(hListview);
  ZeroMemory(@buffer,sizeof(buffer));
  lstrcpy(buffer,pchar(Format('%d ' + GrammarEntry[i=1],[i])));
  SendMessage(hStatusbar,SB_SETTEXT,0,LPARAM(@buffer));
  ZeroMemory(@buffer,sizeof(buffer));
  SendMessage(hStatusbar,SB_SETTEXT,1,LPARAM(@buffer));

  BeginUpdate(hListview,false);
  DestroyWindow(dlg);
end;

//
// show URL
//
var
  SortMode : byte = 0;

procedure ShowFocusedUrl;
var
  i : integer;
begin
  if(SortMode = 1) then exit;

  i := ListView_GetNextItem(hListview,-1,LVNI_FOCUSED);

  // enable buttons
  SendMessage(hToolbar,TB_ENABLEBUTTON,IDC_DELBTN,
    LPARAM((i > -1) and (IsAdmin)));

  if(i > -1) then begin
    // get "DisplayName"
    ListView_GetItemText(hListview,i,1,buffer,sizeof(buffer));
    if(buffer[0] = #0) or (lstrcmp(buffer,szUnknown) = 0) then begin
      // get "QuietDisplayName"
      ListView_GetItemText(hListview,i,3,buffer,sizeof(buffer));

      // get internal name as last chance
      if(buffer[0] = #0) or (lstrcmp(buffer,szUnknown) = 0) then
        ListView_GetItemText(hListview,i,0,buffer,sizeof(buffer));
    end;

    // update statusbar
    if(buffer[0] <> #0) then
      SendMessage(hStatusbar,SB_SETTEXT,1,LPARAM(@buffer));

    // enable Edit & Deinstall buttons
    ListView_GetItemText(hListview,i,2,buffer,sizeof(buffer));
    if(buffer[0] = #0) or (lstrcmp(buffer,szNotFound) = 0) then
      ListView_GetItemText(hListview,i,4,buffer,sizeof(buffer));

    SendMessage(hToolbar,TB_ENABLEBUTTON,IDC_DEINSTALLBTN,
      LPARAM((buffer[0]<>#0) and (IsAdmin) and (lstrcmp(buffer,szNotFound)<>0)));
    SendMessage(hToolbar,TB_ENABLEBUTTON,IDC_EDITBTN,
      LPARAM((buffer[0]<>#0) and (IsAdmin) and (lstrcmp(buffer,szNotFound)<>0)));
  end;
end;

//
// deletes a Registry key
//
function DelRecurse(parent: HKEY; szKeyName: string): cardinal;
var
  reg       : HKEY;
  dwSubkeys : dword;
  dwLen     : dword;
  i         : integer;
  buf       : array[0..MAX_PATH]of char;
begin
  // are there any sub-keys?
  if(RegOpenKeyEx(parent,@szKeyName[1],0,KEY_READ,reg) = ERROR_SUCCESS) then
  try
    if(RegQueryInfoKey(reg,nil,nil,nil,@dwSubKeys,nil,
      nil,nil,nil,nil,nil,nil) = ERROR_SUCCESS) and
      (dwSubKeys > 0) then
    for i := 0 to dwSubKeys - 1 do begin
      ZeroMemory(@buf,sizeof(buf));
      dwLen   := MAX_PATH;

      if(RegEnumKeyEx(reg,i,buf,dwLen,nil,nil,nil,nil) = ERROR_SUCCESS) and
        (dwLen > 0) then DelRecurse(reg,buf);
    end;
  finally
    RegCloseKey(reg);
  end;

  // delete
  Result := RegDeleteKey(parent,@szKeyName[1]);
end;

procedure DeleteRegKey;
var
  i : integer;
begin
  if(not IsAdmin) then exit;

  i := ListView_GetNextItem(hListview,-1,LVNI_FOCUSED);
  if(i > -1) then begin
    ListView_GetItemText(hListview,i,0,buffer,sizeof(buffer));

    if(buffer[0] <> #0) and
      (MessageBox(0,pchar('Do you want the key "' +
         szUnInst + '\' + buffer + '" really remove?'),
         'UnInstall Secrets',
         MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2) = ID_YES) then
    begin
      if(DelRecurse(HKEY_LOCAL_MACHINE,szUnInst + '\' + buffer) =
        ERROR_SUCCESS) then
      ListView_DeleteItem(hListview,i);
    end;
  end;

  // update statusbar
  i := ListView_GetItemCount(hListview);
  ZeroMemory(@buffer,sizeof(buffer));
  lstrcpy(buffer,pchar(Format('%d ' + GrammarEntry[i=1],[i])));
  SendMessage(hStatusbar,SB_SETTEXT,0,LPARAM(@buffer));
end;

//
// remove application
//
procedure Deinstall(wnd: HWND);
var
  i   : integer;
  URL : string;
begin
  i := ListView_GetNextItem(hListview,-1,LVNI_FOCUSED);
  if(i > -1) then begin
    ListView_GetItemText(hListview,i,2,buffer,sizeof(buffer));
    if(lstrcmp(buffer,szNotFound) = 0) then
      ListView_GetItemText(hListview,i,4,buffer,sizeof(buffer));

    if(buffer[0] <> #0) and (lstrcmp(buffer,szNotFound) <> 0) then begin
      URL := buffer;
      ListView_GetItemText(hListview,i,0,buffer,sizeof(buffer));

      // U´R leaving the Highway! :o)
      if(MessageBox(wnd,
        pchar('Are you sure you want to uninstall... "' + buffer
        + '" want to start?'),'UnInstall Secrets',
        MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2) = ID_YES) then
      begin
        ShowWindow(wnd,SW_HIDE);
        WinExec32AndWait(URL,SW_SHOWNORMAL);
        ShowWindow(wnd,SW_SHOW);

        // update TListView
        LoadRegKeys;
      end;
    end;
  end;
end;

//
// change "DisplayName" and/or "QuietDisplayName"
//
procedure Input(wnd: HWND);
var
  dlg      : HWND;
  msg      : TMsg;
  i,
  iRes     : integer;
  fEdit    : boolean;
  rgHandle : HKEY;
  dn,
  qdn      : string;
begin
  i := ListView_GetNextItem(hListview,-1,LVNI_FOCUSED);

  if(i > -1) then begin
    // check uninstall strings
    ZeroMemory(@buffer,sizeof(buffer));
    ListView_GetItemText(hListview,i,2,buffer,sizeof(buffer));
    fEdit := (lstrcmp(szNotFound,buffer) <> 0);
    if(not fEdit) then begin
      ZeroMemory(@buffer,sizeof(buffer));
      ListView_GetItemText(hListview,i,4,buffer,sizeof(buffer));

      fEdit := (lstrcmp(szNotFound,buffer) <> 0);
    end;
    if(not fEdit) then exit;

    // create input dialog
    fChanged := false;
    dlg      := CreateDialog(hInstance,MAKEINTRESOURCE(200),wnd,@inputdlgproc);
    if(dlg = 0) then exit;

    // get "DisplayName"
    ListView_GetItemText(hListview,i,1,buffer,sizeof(buffer));
    SetWindowText(GetDlgItem(dlg,IDC_DISPNAME),buffer);

    // get "QuietDisplayName"
    ListView_GetItemText(hListview,i,3,buffer,sizeof(buffer));
    SetWindowText(GetDlgItem(dlg,IDC_QUIETNAME),buffer);

    // dialog message pump
    while(GetMessage(msg,0,0,0)) do IsDialogMessage(dlg,msg);

    // something was changed
    if(fChanged) then begin
      SetLength(dn,255);
      SetLength(dn,GetWindowText(GetDlgItem(dlg,IDC_DISPNAME),
        @dn[1],length(dn)));
      if(lstrcmp(@dn[1],szUnknown) = 0) then SetLength(dn,0);

      SetLength(qdn,255);
      SetLength(qdn,GetWindowText(GetDlgItem(dlg,IDC_QUIETNAME),
        @qdn[1],length(qdn)));
      if(lstrcmp(@qdn[1],szUnknown) = 0) then SetLength(qdn,0);

      // open Registry
      ZeroMemory(@buffer,sizeof(buffer));
      ListView_GetItemText(hListview,i,0,buffer,sizeof(buffer));

      if(RegOpenKeyEx(HKEY_LOCAL_MACHINE,pchar(szUnInst + '\' + buffer),0,
        KEY_READ or KEY_WRITE,rgHandle) = ERROR_SUCCESS) then
      try
        // write new "DisplayName"
        if(dn = '') then iRes := RegDeleteValue(rgHandle,'DisplayName')
          else iRes := RegSetValueEx(rgHandle,'DisplayName',0,REG_SZ,
            @dn[1],length(dn)+1);
        if(iRes = ERROR_SUCCESS) then begin
          if(dn = '') then dn := szUnknown;
          ListView_SetItemText(hListview,i,1,@dn[1]);
        end;

        // write new "QuietDisplayName"
        if(qdn = '') then iRes := RegDeleteValue(rgHandle,'QuietDisplayName')
          else iRes := RegSetValueEx(rgHandle,'QuietDisplayName',0,REG_SZ,
            @qdn[1],length(dn)+1);
        if(iRes = ERROR_SUCCESS) then begin
          if(qdn = '') then qdn := szUnknown;
          ListView_SetItemText(hListview,i,3,@qdn[1]);
        end;
      finally
        RegCloseKey(rgHandle);
      end;
    end;

    DestroyWindow(dlg);
  end;
end;

//
// move a Registry key
//
function Reg_MoveKey(const szOldName, szNewName: string): integer;
const
  dwDefNameSize = 16383;
var
  ValueName     : pchar;
  ValueBuf      : pointer;
  dwDefBufSize,
  dwBufSize,
  dwNameSize    : dword;
  idx,
  status        : integer;
  lpType        : dword;
  fError        : boolean;

  procedure CopyValues(const src, dest: HKEY);
  begin
    if(src = dest) then exit;

    if(RegQueryInfoKey(src,nil,nil,nil,nil,nil,nil,nil,nil,
      @dwDefBufSize,nil,nil) <> ERROR_SUCCESS) then dwBufSize := 8192;

    GetMem(ValueName,dwDefNameSize);
    try
      GetMem(ValueBuf,dwBufSize);
      try
        idx := 0;

        repeat
          dwBufSize  := dwDefBufSize;
          dwNameSize := dwDefNameSize;

          // enumerate values@current key
          status     := RegEnumValue(src,idx,ValueName,
            dwNameSize,nil,@lpType,ValueBuf,@dwBufSize);

          if(status = ERROR_SUCCESS) then begin
            // move value to the new key
            status := RegSetValueEx(dest,ValueName,0,
              lpType,ValueBuf,dwBufSize);

            // increase index for next loop
            inc(idx);
          end;

          // is something wrong?
          fError := (status <> ERROR_SUCCESS) and
            (status <> ERROR_NO_MORE_ITEMS);

        until(status <> ERROR_SUCCESS);
      finally
        FreeMem(ValueBuf,dwBufSize);
      end;
    finally
      FreeMem(ValueName,dwDefNameSize);
    end;
  end;

  procedure CopyKeys(const src, dest: HKEY);
  var
    NewTo : HKEY;
  begin
    if(src = dest) then exit;

    dwNameSize := MAX_PATH + 1;
    GetMem(ValueName,dwNameSize);
    try
      idx := 0;

      repeat
        dwNameSize := MAX_PATH + 1;
        status     := RegEnumKeyEx(src,idx,ValueName,dwNameSize,
          nil,nil,nil,nil);

        // is something wrong?
        fError     := (status <> ERROR_SUCCESS) and
          (status <> ERROR_NO_MORE_ITEMS);
        if(fError) then exit;

        if(status = ERROR_SUCCESS) then begin
          if(RegCreateKeyEx(dest,ValueName,0,nil,0,
            KEY_READ or KEY_WRITE,nil,NewTo,nil) = ERROR_SUCCESS) then
          try
            CopyValues(src,NewTo);
            CopyKeys(src,NewTo);
          finally
            RegCloseKey(NewTo);
          end else
            fError := true;

          // increase index for next loop
          inc(idx);
        end;
      until(status <> ERROR_SUCCESS);
    finally
      FreeMem(ValueName,dwNameSize);
    end;
  end;

var
  oldk,
  newk    : HKEY;
begin
  fError  := false;
  Result  := 0;

  // don´t move if the names are equal or empty!
  if(szOldName = '') or
    (szNewName = '') or
    (lstrcmpi(@szOldName[1],@szNewName[1]) = 0) then exit;

  // open original key
  if(RegOpenKeyEx(HKEY_LOCAL_MACHINE,pchar(szUnInst + '\' + szOldName),
    0,KEY_READ,oldk) = ERROR_SUCCESS) then
  try
    // create copy
    if(RegCreateKeyEx(HKEY_LOCAL_MACHINE,pchar(szUnInst + '\' + szNewName),
      0,nil,0,KEY_READ or KEY_WRITE,nil,newk,nil) = ERROR_SUCCESS) then
    try
      CopyValues(oldk,newk);
      CopyKeys(oldk,newk);

      // no errors while copying
      if(not fError) then Result := 1;
    finally
      RegCloseKey(newk);
    end;
  finally
    RegCloseKey(oldk);

    // no errors! so delete the old key!
    if(not fError) then
      RegDeleteKey(HKEY_LOCAL_MACHINE,pchar(szUnInst + '\' + szOldName));
  end;
end;


//
// Thou art a Sort-Meister
//
function CompareFunc(lp1, lp2, SortType: LPARAM): integer; stdcall;
var
  buf1,
  buf2 : array[0..MAX_PATH]of char;
begin
  ListView_GetItemText(hListview,lp1,SortType,buf1,sizeof(buf1));
  ListView_GetItemText(hListview,lp2,SortType,buf2,sizeof(buf2));

  Result := lstrcmpi(@buf1[1],@buf2[1]);
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


//
// "WndProc"
//
const
  iWidth        = 636;
  iHeight       = 340;
  IDC_LISTVIEW  = 1;
  IDC_TOOLBAR   = 2;
  IDC_STATUS    = 3;
var
  hBmp          : HBITMAP;
  tbBtn         : array[0..4]of TTBButton =
    ((iBitmap:0;
      idCommand:IDC_EDITBTN;
      fsState:0;
      fsStyle:BTNS_BUTTON;
      dwData:0;
      iString:0;),
     (iBitmap:1;
      idCommand:IDC_DELBTN;
      fsState:0;
      fsStyle:BTNS_BUTTON;
      dwData:0;
      iString:0;),
     (iBitmap:2;
      idCommand:IDC_DEINSTALLBTN;
      fsState:0;
      fsStyle:BTNS_BUTTON;
      dwData:0;
      iString:0;),
     (iBitmap:-1;
      idCommand:0;
      fsState:TBSTATE_ENABLED;
      fsStyle:BTNS_SEP;
      dwData:0;
      iString:0;),
     (iBitmap:3;
      idCommand:IDC_REFRESHBTN;
      fsState:TBSTATE_ENABLED;
      fsStyle:BTNS_BUTTON;
      dwData:0;
      iString:0;));


function WndProc(wnd: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM): LRESULT;
  stdcall;
var
  r        : TRect;
  h1,
  h2       : integer;
  cm       : TColorMap;
  aBmp     : TTBAddBitmap;
  pw       : array[0..1]of integer;
  i        : integer;
begin
  Result := 0;

  case uMsg of
    WM_CREATE:
      begin
        // create toolbar, & toolbar bitmap
        hToolbar := CreateWindowEx(0,TOOLBARCLASSNAME,nil,
          WS_CHILD or WS_VISIBLE or CCS_NODIVIDER or
          TBSTYLE_TOOLTIPS or TBSTYLE_FLAT or TBSTYLE_TRANSPARENT,
          0,0,0,0,wnd,IDC_TOOLBAR,hInstance,nil);
        SendMessage(hToolbar,TB_BUTTONSTRUCTSIZE,sizeof(TTBBUTTON),0);
        SendMessage(hToolbar,TB_ADDBUTTONS,5,LPARAM(@tbBtn));

        cm.cFrom   := $00ff00ff;
        cm.cTo     := GetSysColor(COLOR_BTNFACE);                                        
        hBmp       := CreateMappedBitmap(hInstance,300,0,@cm,1);
        aBmp.hInst := 0;
        aBmp.nID   := hBmp;
        SendMessage(hToolbar,TB_ADDBITMAP,4,LPARAM(@aBmp));

        // create statusbar, & panels
        hStatusbar := CreateWindowEx(0,STATUSCLASSNAME,nil,WS_CHILD or
          WS_VISIBLE,0,0,0,0,wnd,IDC_STATUS,hInstance,nil);
        pw[0]      := 120;
        pw[1]      := -1;
        SendMessage(hStatusbar,SB_SETPARTS,2,LPARAM(@pw));

        // create listview
        hListview := CreateWindowEx(WS_EX_CLIENTEDGE,'SysListView32',
          nil,LVS_REPORT or LVS_SINGLESEL or WS_CHILD
          or WS_VISIBLE,0,0,0,0,wnd,IDC_LISTVIEW,hInstance, nil);

        // enable Label editing with Admin rights
        if(IsAdmin) then SetWindowLong(hListview,GWL_STYLE,
          GetWindowLong(hListview,GWL_STYLE) or LVS_EDITLABELS);

        SendMessage(hListView,LVM_SETEXTENDEDLISTVIEWSTYLE,0,
          LVS_EX_FULLROWSELECT
          {$IFDEF GRIDLINES} or LVS_EX_GRIDLINES {$ENDIF});

        // create columns, & load registry keys
        MakeLVColumns(hListview);
        LoadRegKeys;
        SetFocus(hListview);

        // what´s selected?
        UpdateLParam(hListview);
        ListView_SortItems(hListview,@CompareFunc,0);

        if (IsWindowsXP) then ListView_SetSelectedColumn(hListview,0);
      end;
    WM_GETMINMAXINFO:
      begin
        PMinMaxInfo(lp)^.ptMinTrackSize.X := iWidth;
        PMinMaxInfo(lp)^.ptMinTrackSize.Y := iHeight;
      end;
    WM_SIZE:
      begin
        // reset statusbar
        MoveWindow(hStatusbar,0,HIWORD(lp),LOWORD(lp),HIWORD(lp),true);

        // get height of toolbar, & statusbar
        GetClientRect(hToolbar,r);   h1 := r.Bottom - r.Top;
        GetClientRect(hStatusbar,r); h2 := r.Bottom - r.Top;

        // resize Listview
        GetClientRect(wnd,r);
        SetWindowPos(hListview,0,r.left,h1,r.Right - r.Left,
          r.Bottom - r.Top - h1 - h2,SWP_NOZORDER);
      end;
    WM_DESTROY:
      begin
        DeleteObject(hBmp);
        PostQuitMessage(0);
      end;
    WM_COMMAND:
      case HIWORD(wp) of
        BN_CLICKED:
          case LOWORD(wp) of
            IDC_EDITBTN:
              if(IsAdmin) then Input(wnd);
            IDC_DELBTN:
              if(IsAdmin) then DeleteRegKey;
            IDC_DEINSTALLBTN:
              if(IsAdmin) then DeInstall(wnd);
            IDC_REFRESHBTN:
              begin
                LoadRegKeys;

                UpdateLParam(hListview);
                ListView_SortItems(hListview,@CompareFunc,0);
              end;
          end;
      end;
    WM_NOTIFY:
      case PNMHdr(lp)^.code of
        TTN_NEEDTEXT:
          case PToolTiptext(lp)^.hdr.idFrom of
            IDC_EDITBTN:
              PToolTipText(lp)^.lpszText := 'Edit';
            IDC_DELBTN:
              PToolTipText(lp)^.lpszText := 'Remove key';
            IDC_DEINSTALLBTN:
              PToolTipText(lp)^.lpszText := 'Uninstall';
            IDC_REFRESHBTN:
              PToolTipText(lp)^.lpszText := 'Update view';
            else
              Result := DefWindowProc(wnd,uMsg,wp,lp);
          end;
        // "OnDoubleClick"
        NM_DBLCLK:
          if(IsAdmin) then Input(wnd);
        // "OnChange"
        NM_CLICK,
        LVN_ITEMCHANGED:
          ShowFocusedUrl;
        // "OnKeyDown"
        LVN_KEYDOWN:
          case PLVKeyDown(lp)^.wvKey of
            VK_RETURN:
              SendMessage(wnd,WM_COMMAND,MAKEWPARAM(IDC_EDITBTN,BN_CLICKED),0);
            VK_DELETE:
              if(SendMessage(hToolbar,TB_ISBUTTONENABLED,IDC_DELBTN,0) <> 0) and
                (IsAdmin) then DeleteRegKey;
            VK_F2:
              begin
                i := ListView_GetNextItem(hListview,-1,LVNI_FOCUSED);
                if(i > -1) then Listview_EditLabel(hListview,i);
              end;
            VK_F5:
              SendMessage(wnd,WM_COMMAND,MAKEWPARAM(IDC_REFRESHBTN,
              BN_CLICKED),0);
          end;
        // "OnColumnClick"
        LVN_COLUMNCLICK:
          if(PNMHdr(lp)^.hwndFrom = hListview) then begin
            // show selected column
            if(IsWindowsXP) then ListView_SetSelectedColumn(hListview,
              PNMListView(lp)^.iSubItem);

            // sort
            UpdateLParam(hListview);
            ListView_SortItems(hListview,@CompareFunc,
              PNMListView(lp)^.iSubItem);
          end;
        // "OnEdited"
        LVN_ENDLABELEDIT:
          begin
            i := ListView_GetNextItem(hListview,-1,LVNI_FOCUSED);
            if(i > -1) then begin
              ZeroMemory(@buffer,sizeof(buffer));
              ListView_GetItemText(hListview,i,0,buffer,sizeof(buffer));

              // move registry key
              if(PLVDispInfo(lp)^.item.pszText <> nil) then
                Result := Reg_MoveKey(buffer,PLVDispInfo(lp)^.item.pszText)
              else
                Result := 0;
            end;
          end;
      end;
    else
      Result := DefWindowProc(wnd,uMsg,wp,lp);
  end;
end;


{ -- WinMain --------------------------------------------------------------------------------- }

const
  szClassname = 'TUninstallMainForm';
  szAppname   = 'UnInstall Secrets';
  szMutexname = 'Uninstaller10';
var
  wc : TWndClassEx =
    (cbSize:sizeof(TWndClassEx);
     Style:CS_HREDRAW or CS_VREDRAW;
     lpfnWndProc:@WndProc;
     cbClsExtra:0;
     cbWndExtra:0;
     lpszMenuName:nil;
     lpszClassName:szClassName;);
  icc : TInitCommonControlsEx =
    (dwSize : sizeof(TInitCommonControlsEx);
     dwICC  : ICC_LISTVIEW_CLASSES or ICC_BAR_CLASSES;);
  msg : TMsg;
  HMHandle : THandle;
  aWnd : HWND;
begin
  // is UIS already running?
  HMHandle := CreateSemaphore(nil,0,1,szMutexname);
  if(GetLastError = ERROR_ALREADY_EXISTS) then begin
    SendMessage(findwindow(szClassname,nil),WM_SYSCOMMAND,SC_RESTORE,0);
    SetForegroundWindow(findwindow(szClassname,nil));
    exit;
  end;

  // init Common Controls (Listview, Toolbar, & Statusbar)
  InitCommonControlsEx(icc);

  // register class
  wc.hInstance     := hInstance;
  wc.hbrBackground := GetSysColorBrush(COLOR_3DFACE);
  wc.hIcon         := LoadIcon(hInstance,IDI_WINLOGO);
  wc.hCursor       := LoadCursor(0,IDC_ARROW);
  if(RegisterClassEx(wc) = 0) then exit;

  // create window
  aWnd := CreateWindowEx(0,szClassname,szAppname,WS_OVERLAPPEDWINDOW or
    WS_VISIBLE,integer(CW_USEDEFAULT),integer(CW_USEDEFAULT),iWidth,iHeight,
    0,0,hInstance,nil);
  if(aWnd = 0) then exit;
  ShowWindow(aWnd,SW_SHOW);
  UpdateWindow(aWnd);

  // message pump
  while(GetMessage(msg,0,0,0)) do
  begin
    TranslateMessage(msg);
    DispatchMessage (msg);
  end;

  // release mutex
  CloseHandle(HMHandle);
end.