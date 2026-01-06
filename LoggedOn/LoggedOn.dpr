{$INCLUDE CompilerSwitches.inc}

program LoggedOn;

uses
  windows,
  messages,
  CommCtrl,
  SysUtils,
  Types,
  MpuTools in 'units\MpuTools.pas',
  constants in 'units\constants.pas',
  MpuAboutWnd in 'units\MpuAboutWnd.pas',
  List in 'units\List.pas',
  Exceptions in 'units\Exceptions.pas',
  LoggedOnCls in 'units\LoggedOnCls.pas',
  ShutdownDlg in 'units\ShutdownDlg.pas',
  IpHlpApi in 'units\IpHlpApi.pas',
  IpExport in 'units\IpExport.pas',
  IpRtrMib in 'units\IpRtrMib.pas',
  IpTypes in 'units\IpTypes.pas',
  LoggedOnHelpers in 'units\LoggedOnHelpers.pas';

{$R .\res\resource.res}

type
  TThreadParams = packed record
    Machine: string;
    Domain: string;
  end;
  PThreadParams = ^TThreadParams;

var
  hApp              : THandle;
  hImageList        : THandle;
  hUserDlg          : THandle;
  hMachineDlg       : THandle;
  hThread           : THandle;
  TickStart         : DWORD;
  MachineObj        : TComputer;

function FormatTime(t: int64): string; { (gettime by Assarbad) }
begin
  case t mod 1000 < 100 of
    true: result := '0' + result;
  end;
  t := t div 1000; // -> seconds
  result := IntToStr(t mod 60); // + '.' + result;
  case t mod 60 < 10 of
    true: result := '0' + result;
  end;
  t := t div 60; //minutes
  result := IntToStr(t mod 60) + ':' + result;
end;

function FormatUpTime(msecs: int64): string;
var
  dwSecs            : DWORD;
  dwDays            : DWORD;
  ts                : SysUtils.TTimeStamp;
  UpTime            : TDateTime;
begin
  dwDays := 0;
  dwSecs := msecs div 1000;
  if dwSecs >= SecsPerDay then
  begin
    dwDays := dwSecs div SecsPerDay;
    dwSecs := dwSecs mod SecsPerDay;
  end;
  ts.Time := dwSecs * 1000;
  ts.Date := DateDelta;
  UpTime := SysUtils.TimeStampToDateTime(ts);
  Result := Format('%ud %sh %smin', [dwDays, FormatDateTime('h', UpTime),
    FormatDateTime('n', UpTime)])
end;

function GetDlgBtnCheck(hParent: THandle; ID: Integer): Boolean;
begin
  result := IsDlgButtonChecked(hParent, ID) = BST_CHECKED;
end;

procedure SetDlgBtnCheck(Handle: THandle; ID: Integer; bCheck: Boolean);
const
  Check             : array[Boolean] of Integer = (BST_UNCHECKED, BST_CHECKED);
begin
  CheckDlgButton(Handle, ID, Check[bCheck]);
end;

procedure SetItemText(Handle: THandle; ID: Integer; const Text: string);
begin
  SetDlgItemText(Handle, ID, PChar(Text));
end;

function GetItemText(hParent: THandle; ID: Integer): string;
var
  p                 : PChar;
  len               : Integer;
  s                 : string;
begin
  p := nil;
  s := '';
  len := SendDlgItemMessage(hParent, ID, WM_GETTEXTLENGTH, 0, 0);
  if len > 0 then
  begin
    try
      p := GetMemory(len + 1);
      if Assigned(p) then
      begin
        GetDlgItemText(hParent, ID, p, len + 1);
        s := string(p);
      end;
    finally
      FreeMemory(p);
    end;
  end;
  result := s;
end;

procedure DisplayExceptionMsg(hParent: THandle; ErrorCode: Integer; Msg, Caption: string);
var
  s                 : string;
begin
  if Msg = '' then
    Msg := rsErrorUnknown;

  s := Format(rsErrorMsgTemplate, [ErrorCode, Msg]);
  MessageBox(hParent, PChar(s), PChar(Caption), MB_ICONSTOP or MB_APPLMODAL);
end;

procedure ExpandAll(hParent: THandle; ID: Integer; expand: Boolean);
const
  szCode            : array[Boolean] of WPARAM = (TVE_COLLAPSE, TVE_EXPAND);
var
  hTV               : HWND;
  hItem, hNewItem   : HTREEITEM;
begin
  hTV := GetDlgItem(hParent, ID);
  hItem := TreeView_GetRoot(hTV);
  while hItem <> nil do
  begin
    TreeView_Expand(hTV, hItem, szCode[expand]);
    hNewItem := TreeView_GetChild(hTV, hItem);
    if hNewItem = nil then
      hNewItem := TreeView_GetNextSibling(hTV, hItem);
    if hNewItem = nil then
      hNewItem := TreeView_GetNextSibling(hTV, TreeView_GetParent(hTV, hItem));
    hItem := hNewItem;
  end;
  TreeView_Expand(hTV, TreeView_GetRoot(hTV), TVE_EXPAND);
end;

function FillTreeview(Machine: string; UserList: TLoggedOnUserCollection): Boolean;
var
  hTV               : THandle;
  tvi               : TTVInsertStruct;
  hr                : HTREEITEM;
  i                 : Integer;
  MachineObj        : TComputer;
begin
  Result := False;
  MachineObj := TComputer.Create(Machine);

  hTV := GetDlgItem(hApp, IDC_TRV);
  SendMessage(hTV, WM_SETREDRAW, Integer(False), 0);

  if (UserList = nil) or (UserList.Count = 0) then
    Exit;

  ZeroMemory(@tvi, sizeof(tvi));
  tvi.hParent := nil;
  tvi.hInsertAfter := TVI_ROOT;
  tvi.item.mask := TVIF_TEXT or TVIF_IMAGE or TVIF_SELECTEDIMAGE or TVIF_PARAM;
  tvi.item.iImage := 0;
  tvi.item.iSelectedImage := 0;
  tvi.item.lParam := LPARAM(MachineObj);
  tvi.item.pszText := PChar(Machine);
  hr := TreeView_InsertItem(hTV, tvi);
  for i := 0 to UserList.Count - 1 do
  begin
    tvi.hParent := hr;
    tvi.hInsertAfter := TVI_SORT;
    tvi.item.iImage := 1;
    tvi.item.iSelectedImage := 1;
    tvi.item.lParam := LPARAM(UserList.Items[i]);
    tvi.item.pszText := PChar(Format('%s', [UserList.Items[i].Username]));
    TreeView_InsertItem(hTV, tvi);
  end;

  ExpandAll(hApp, IDC_TRV, True);
  SendMessage(hTV, WM_SETREDRAW, Integer(True), 0);
  TreeView_SelectItem(hTV, TreeView_GetRoot(hTV));

  Result := True;
end;

function FillTreeview2(Domain: string; MachineList: TMachineCollection): Boolean;
var
  hTV               : THandle;
  tvi               : TTVInsertStruct;
  hr                : HTREEITEM;
  hParent           : HTREEITEM;
  i, j              : Integer;
  s                 : string;
begin
  Result := False;
  hTV := GetDlgItem(hApp, IDC_TRV);
  SendMessage(hTV, WM_SETREDRAW, Integer(False), 0);

  if (MachineList = nil) or (MachineList.Count = 0) then
    Exit;

  ZeroMemory(@tvi, sizeof(tvi));
  tvi.hParent := nil;
  tvi.hInsertAfter := TVI_ROOT;
  tvi.item.mask := TVIF_TEXT or TVIF_IMAGE or TVIF_SELECTEDIMAGE or TVIF_PARAM;
  tvi.item.iImage := 2;
  tvi.item.iSelectedImage := 2;
  tvi.item.pszText := PChar(Domain);
  hr := TreeView_InsertItem(hTV, tvi);
  try
    for i := 0 to MachineList.Count - 1 do
    begin
      tvi.hParent := hr;
      tvi.hInsertAfter := TVI_SORT;
      tvi.item.iImage := 0;
      tvi.item.iSelectedImage := 0;
      tvi.item.lParam := LPARAM(MachineList.Items[i]);
      tvi.item.pszText := PChar('\\' + MachineList.Items[i].Machine);
      hParent := TreeView_InsertItem(hTV, tvi);
      if MachineList.Items[i].LoggedOnUsers <> nil then
      begin
        for j := 0 to MachineList.Items[i].LoggedOnUsers.Count - 1 do
        begin
          tvi.hParent := hParent;
          tvi.hInsertAfter := TVI_SORT;
          tvi.item.iImage := 1;
          tvi.item.iSelectedImage := 1;
          tvi.item.lParam := LPARAM(nil);
          tvi.item.lParam := LPARAM(MachineList.Items[i].LoggedOnUsers.Items[j]);
          s := Format('%s', [MachineList.Items[i].LoggedOnUsers.Items[j].Username]);
          tvi.item.pszText := PChar(s);
          TreeView_InsertItem(hTV, tvi);
        end;
      end;
    end;
  except

  end;

  ExpandAll(hApp, IDC_TRV, True);
  SendMessage(hTV, WM_SETREDRAW, Integer(True), 0);
  TreeView_SelectItem(hTV, TreeView_GetRoot(hTV));

  Result := True;
end;

function ScanMachine(p: Pointer): Integer;
var
  UserList          : TLoggedOnUserCollection;
  Machine           : string;
  s                 : string;
begin
  Machine := PThreadParams(p)^.Machine;
  s := Format(rsScanMachine, [Machine]);
  SendMessage(hApp, TM_START, 0, Integer((PChar(s))));

  try
    UserList := TLoggedOnUserCollection.GetAllUsers(Machine, emOn);
    if FillTreeView(Machine, UserList) then
      s := Format(rsFinishMachine, [UserList.Count])
    else
      s := '';
    SendDlgItemMessage(hApp, IDC_SBR, SB_SETTEXT, 0, Integer(PChar(s)));
  except
    on E: Exception do
    begin
      SendMessage(hApp, TM_DONE, 1, 0);
      DisplayExceptionMsg(hApp, E.Errorcode, string(E.Message), APPNAME);
      Result := 0;
      exit;
    end;
  end;

  FreeMemory(p);
  Result := 0;

  PostMessage(hApp, TM_DONE, 0, 0);
end;

function ScanDomain(p: Pointer): Integer;
var
  MachineList       : TMachineCollection;
  Domain            : string;
  s                 : string;
begin
  Domain := PThreadParams(p)^.Domain;
  s := Format(rsScanDomain, [Domain]);
  SendMessage(hApp, TM_START, 0, Integer(PChar(s)));

  try
    MachineList := TMachineCollection.GetAllMachines(PThreadParams(p)^.Domain, emOn);
    if FillTreeView2(Domain, MachineList) then
      s := Format(rsFinishDomain, [MachineList.Count])
    else
      s := '';
    SendDlgItemMessage(hApp, IDC_SBR, SB_SETTEXT, 0, Integer(PChar(s)));
  except
    on E: Exception do
    begin
      SendMessage(hApp, TM_DONE, 1, 0);
      DisplayExceptionMsg(hApp, E.Errorcode, string(E.Message), APPNAME);
      FreeMemory(p);
      Result := 0;
      exit;
    end;
  end;

  FreeMemory(p);
  Result := 0;

  SendMessage(hApp, TM_DONE, 0, 0);
end;

function dlgfunc(hDlg: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;
var
  MyFont            : HFONT;
  s                 : string;
  rect              : TRect;
  i                 : Integer;
  hIcon             : THandle;
  pt                : TPoint;
  Machine           : string;
  Obj               : TObject;
  LoggedOnUser      : TLoggedOnUser;
  Domain            : string;
  ThreadParams      : PThreadParams;
  ThreadID          : Cardinal;
  Panels            : array[0..2] of Integer;
  Flag              : Integer;
  fi                : TFlashWInfo;
  TickDif           : DWORD;
  ShutdownParams    : TShutdownParams;
  InfoText          : String;
begin
  result := true;
  case uMsg of
    WM_INITDIALOG:
      begin
        hApp := hDlg;
        EnableControl(hDlg, IDC_BTN_CANCEL, False);
        EnableControl(hDlg, IDC_BTN_SCAN, False);
        //SetDlgBtnCheck(hDlg, IDC_RBN_MACHINE, True);

        // Dialog icon
        if SendMessage(hDlg, WM_SETICON, ICON_SMALL, Integer(LoadIcon(hInstance, MAKEINTRESOURCE(1)))) = 0 then
          SendMessage(hDlg, WM_SETICON, ICON_BIG, Integer(LoadIcon(hInstance, MAKEINTRESOURCE(1))));
        // Banner font
        MyFont := CreateFont(FONTSIZE, 0, 0, 0, 900, 0, 0, 0, ANSI_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
          DEFAULT_QUALITY, DEFAULT_PITCH, FONTNAME);
        if MyFont <> 0 then
          SendDlgItemMessage(hDlg, IDC_STC_BANNER, WM_SETFONT, Integer(MyFont), Integer(true));
        // TV Font
        MyFont := CreateFont(FONTSIZE_TV, 0, 0, 0, 400, 0, 0, 0, ANSI_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
          DEFAULT_QUALITY, DEFAULT_PITCH, FONT_TV);
        if MyFont <> 0 then
          SendDlgItemMessage(hDlg, IDC_TRV, WM_SETFONT, Integer(MyFont), Integer(true));
        // Window caption and banner caption
        s := APPNAME;
        SetWindowText(hDlg, pointer(s));
        SetDlgItemText(hDlg, IDC_STC_BANNER, pointer(s));
        // ImageList
        hImageList := ImageList_Create(16, 16, ILC_COLORDDB or ILC_MASK, 7, 0);
        for i := 2 to 4 do
        begin
          hIcon := LoadIcon(hInstance, MAKEINTRESOURCE(i));
          ImageList_AddIcon(hImageList, hIcon);
        end;
        ImageList_AddIcon(hImageList, hIcon);
        // Treeview
        TreeView_SetImageList(GetDlgItem(hDlg, IDC_TRV), hImageList, TVSIL_NORMAL);
        ShowWindow(GetDlgItem(hDlg, IDC_ANI_SEARCH), SW_HIDE);
        // Info dialogs
        hUserDlg := CreateDialog(HInstance, MAKEINTRESOURCE(200), hDlg, nil);
        ShowWindow(hUserDlg, SW_HIDE);
        hMachineDlg := CreateDialog(HInstance, MAKEINTRESOURCE(300), hDlg, nil);
        ShowWindow(hMachineDlg, SW_HIDE);
        ShowWindow(GetDlgItem(hDlg, IDC_BTN_SHUTDOWN), SW_HIDE);
      end;
    WM_CTLCOLORSTATIC:
      begin
        case GetDlgCtrlId(lParam) of
          IDC_STC_BANNER: { color the banner white }
            begin
              result := BOOL(GetStockObject(WHITE_BRUSH));
            end;
        else
          Result := False;
        end;
      end;
    { move the window with the left button down }
    WM_LBUTTONDOWN:
      begin
        SetCursor(LoadCursor(0, IDC_SIZEALL));
        SendMessage(hDlg, WM_NCLBUTTONDOWN, HTCAPTION, lParam);
      end;
    WM_SIZE:
      begin
        MoveWindow(GetDlgItem(hDlg, IDC_STC_BANNER), 0, 0, loword(lParam), 75, True);
        s := APPNAME;
        SetDlgItemText(hDlg, IDC_STC_BANNER, pointer(s));
        SetWindowPos(GetDlgItem(hDlg, IDC_BTN_ABOUT), GetDlgItem(hDlg, IDC_STC_BANNER), loword(lParam) - 47, 7, 40, 22,
          SWP_SHOWWINDOW);

        GetWindowRect(GetDlgItem(hDlg, IDC_STC_BANNER), rect);
        pt.X := rect.Left;
        pt.Y := rect.Bottom;
        ScreenToClient(hDlg, pt);
        MoveWindow(GetDlgItem(hDlg, IDC_STC_DEVIDER), 0, 75, loword(lParam), 2, False);

        GetWindowRect(hDlg, rect);
        pt.X := rect.Right;
        pt.Y := rect.Top;
        ScreenToClient(hDlg, pt);
        SetWindowPos(hUserDlg, 0, loword(lParam) - 160, 86, 0, 0, SWP_NOSIZE);
        SetWindowPos(hMachineDlg, 0, loword(lParam) - 160, 86, 0, 0, SWP_NOSIZE);
        SetWindowPos(GetDlgItem(hDlg, IDC_STC_HINT), 0, loword(lParam) - 140, hiword(lParam) div 2, 0, 0, SWP_NOSIZE);
        SetWindowPos(GetDlgItem(hDlg, IDC_ANI_SEARCH), 0, loword(lParam) - 120, hiword(lParam) div 2 - 50, 0, 0, SWP_NOSIZE);
        SetWindowPos(GetDlgItem(hDlg, IDC_SBR), 0, 0, hiword(lParam) - 22, loword(lParam), 0, SWP_SHOWWINDOW);
        SetWindowPos(GetDlgItem(hDlg, IDC_TRV), 0, 5, 80, loword(lParam) - 175, hiword(lParam) - 140, SWP_SHOWWINDOW);

        GetClientRect(hDlg, rect);
        Panels[0] := 250;
        Panels[1] := rect.Right - rect.Left - 55;
        Panels[2] := -1;
        SendDlgItemMessage(hDlg, IDC_SBR, SB_SETPARTS, 3, Integer(@Panels));
        SendDlgItemMessage(hDlg, IDC_SBR, SB_SETTEXT, 2, Integer(PChar(TAboutWnd.GetFileVersion(ParamStr(0)))));

        InvalidateRect(hDlg, nil, False);
        RedrawWindow(hDlg, nil, 0, RDW_UPDATENOW);
      end;
    WM_TIMER:
      begin
        TickDif := GetTickCount - TickStart;
        SendDlgItemMessage(hDlg, IDC_SBR, SB_SETTEXT, 1, Integer(PChar(Format(rsTime, [FormatTime(TickDif)]))));
      end;
    WM_CLOSE:
      begin
        EndDialog(hDlg, 0);
      end;
    WM_COMMAND:
      begin
        { accel for closing the dialog with ESC }
        if wParam = ID_CANCEL then
          SendMessage(hDlg, WM_CLOSE, 0, 0);
        { button and menu clicks }
        if hiword(wParam) = BN_CLICKED then
        begin
          case LoWord(wParam) of
            IDC_BTN_ABOUT:
              begin
                TAboutWnd.MsgBox(hDlg, 1);
              end;
            IDC_BTN_MACHINE:
              begin
                if FindComputer(hDlg, 'Open machine to scan for logged on users:', Machine) then
                begin
                  New(ThreadParams);
                  ThreadParams.Machine := Machine;
                  hThread := BeginThread(nil, 0, @ScanMachine, ThreadParams, 0, ThreadID);
                end;
              end;
            IDC_BTN_DOMAIN:
              begin
                if FindDomain(hDlg, 'Open domain to scan for machines with logged on users:', Domain) then
                begin
                  New(ThreadParams);
                  ThreadParams.Domain := Domain;
                  hThread := BeginThread(nil, 0, @ScanDomain, ThreadParams, 0, ThreadID);
                end
              end;
            IDC_BTN_CANCEL:
              begin
                if hThread <> 0 then
                begin
                  TerminateThread(hThread, 0);
                  KillTimer(hDlg, 0);
                  SendDlgItemMessage(hDlg, IDC_SBR, SB_SETTEXT, 1, Integer(PChar(nil)));
                  ShowWindow(hUserDlg, SW_HIDE);
                  ShowWindow(hMachineDlg, SW_HIDE);
                  ShowWindow(GetDlgItem(hDlg, IDC_ANI_SEARCH), SW_HIDE);
                  EnableControl(hDlg, IDC_BTN_CANCEL, False);
                  SendDlgItemMessage(hDlg, IDC_SBR, SB_SETTEXT, 0, Integer(nil));
                end;
              end;
            IDC_BTN_SHUTDOWN:
              begin
                if Assigned(MachineObj) then
                begin
                  ShutdownParams.Machine := MachineObj.Machine;
                  DialogBoxParam(HInstance, MAKEINTRESOURCE(400), hDlg, @ShutdownDlgFunc, Integer(@ShutdownParams));
                end;
              end;
          end;
        end;
      end;
    TM_START:
      begin
        TickStart := GetTickCount;
        SetTimer(hDlg, 0, 1000, nil);
        SendDlgItemMessage(hDlg, IDC_SBR, SB_SETTEXT, 1, Integer(PChar(Format(rsTime, [FormatTime(0)]))));
        ShowWindow(GetDlgItem(hApp, IDC_STC_HINT), SW_HIDE);
        ShowWindow(hUserDlg, SW_HIDE);
        ShowWindow(hMachineDlg, SW_HIDE);
        ShowWindow(GetDlgItem(hApp, IDC_ANI_SEARCH), SW_SHOW);
        EnableControl(hDlg, IDC_BTN_SCAN, False);
        EnableControl(hDlg, IDC_BTN_CANCEL, True);
        SetFocus(GetDlgItem(hDlg, IDC_BTN_CANCEL));
        s := string(lParam);
        SendDlgItemMessage(hApp, IDC_SBR, SB_SETTEXT, 0, Integer(PChar(s)));
        TreeView_DeleteAllItems(GetDlgItem(hApp, IDC_TRV));
      end;
    TM_DONE:
      begin
        if wParam = 1 then
        begin
          SendDlgItemMessage(hApp, IDC_SBR, SB_SETTEXT, 0, Integer(nil));
        end;
        if TreeView_GetCount(GetDlgItem(hDlg, IDC_TRV)) > 0 then
          ShowWindow(GetDlgItem(hApp, IDC_STC_HINT), SW_SHOW)
        else
          ShowWindow(GetDlgItem(hApp, IDC_STC_HINT), SW_HIDE);
        KillTimer(hDlg, 0);
        ShowWindow(GetDlgItem(hApp, IDC_ANI_SEARCH), SW_HIDE);
        EnableControl(hDlg, IDC_BTN_CANCEL, False);
        fi.cbSize := sizeof(TFlashWInfo);
        fi.hwnd := hApp;
        fi.dwFlags := FLASHW_TRAY or FLASHW_TIMERNOFG;
        fi.uCount := 4;
        FlashWindowEx(fi);
        SetFocus(GetDlgItem(hDlg, IDC_TRV));
      end;
    WM_NOTIFY:
      begin
        if PNMHdr(lParam).idFrom = IDC_TRV then
        begin
          case PNMHDR(lParam)^.code of
            TVN_SELCHANGED:
              begin
                Obj := TObject(PNMTreeViewW(PNMHDR(lParam))^.itemNew.lParam);
                if Assigned(Obj) then
                begin
                  if not ((Obj is TLoggedOnUser) or (Obj is TComputer)) then
                    Flag := SW_SHOW
                  else
                    Flag := SW_HIDE;
                  ShowWindow(GetDlgItem(hDlg, IDC_STC_HINT), Flag);
                  if Obj is TLoggedOnUser then
                  begin
                    ShowWindow(hUserDlg, SW_SHOW);
                    LoggedOnUser := TLoggedOnUser(Obj);
                    InfoText := 'Username: ' + LoggedOnUser.Username + #13#10 + 'Logon domain: ' + LoggedOnUser.LogonDomain +
                      #13#10 + 'Logon server: ' + LoggedOnUser.LogonServer;
                    SetDlgItemText(hUserDlg, IDC_EDT_USER, PChar(InfoText));
                  end
                  else
                  begin
                    ShowWindow(hUserDlg, SW_HIDE);
                    SetDlgItemText(hUserDlg, IDC_EDT_USER, nil);
                  end;
                  if Obj is TComputer then
                  begin
                    ShowWindow(hMachineDlg, SW_SHOW);
                    ShowWindow(GetDlgItem(hDlg, IDC_BTN_SHUTDOWN), SW_SHOW);
                    MachineObj := TComputer(Obj);
                    InfoText := 'Machine: ' + MachineObj.Machine + #13#10 + 'Domain: ' + MachineObj.LanGroup + #13#10 +
                      'IP: ' + MachineObj.IP + #13#10 + 'MAC: ' + MachineObj.MAC + #13#10 + 'OS: ' + MachineObj.OS +
                      #13#10 + 'Comment: ' + MachineObj.Comment + #13#10 + 'Uptime: ' + FormatUpTime(MachineObj.ToD.tod_msecs);
                    SetDlgItemText(hMachineDlg, IDC_EDT_MACHINE, PChar(InfoText));
                  end
                  else
                  begin
                    ShowWindow(hMachineDlg, SW_HIDE);
                    ShowWindow(GetDlgItem(hDlg, IDC_BTN_SHUTDOWN), SW_HIDE);
                    SetDlgItemText(hMachineDlg, IDC_EDT_MACHINE, nil);
                  end;
                end
                else
                begin
                  ShowWindow(GetDlgItem(hDlg, IDC_STC_HINT), SW_SHOW);
                  ShowWindow(GetDlgItem(hDlg, IDC_BTN_SHUTDOWN), SW_HIDE);
                  ShowWindow(hUserDlg, SW_HIDE);
                  ShowWindow(hMachineDlg, SW_HIDE);
                end;
              end;
          end;
        end;
      end;
  else
    result := false;
  end;
end;

begin
  InitCommonControls;
  DialogBox(hInstance, MAKEINTRESOURCE(100), 0, @dlgfunc);
end.

