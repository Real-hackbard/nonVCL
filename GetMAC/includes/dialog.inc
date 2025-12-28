procedure SetDialogIcon(Handle: THandle);
var
    hIcon : THandle;
begin
  hIcon := LoadImage(hInstance, MAKEINTRESOURCE(1), IMAGE_ICON, 16, 16, LR_DEFAULTCOLOR);
  if hIcon <> 0 then
  begin
    if SendMessage(Handle, WM_SETICON, ICON_SMALL, hIcon) = 0 then
      SendMessage(Handle, WM_SETICON, ICON_BIG, hIcon);
  end;
end;

procedure SetBannerFont(Handle: THandle);
var
  MyFont: HFONT;
begin
  MyFont := CreateFont(FONTSIZE, 0, 0, 0, 900, 0, 0, 0, ANSI_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
    DEFAULT_QUALITY, DEFAULT_PITCH, FONTNAME);
  if MyFont <> 0 then
  begin
    SendDlgItemMessage(Handle, IDC_STC_BANNER, WM_SETFONT, Integer(MyFont), Integer(true));
  end;
end;

procedure SetCaptions(Handle: Thandle);
var
  s : string;
begin
  s := GetFileInfo(ParamStr(0), 'ProductName');
  SetWindowText(Handle, pointer(s));
  SetDlgItemText(Handle, IDC_STC_BANNER, pointer(s));
end;

procedure SetToolTips(Handle: THandle);
var
  i: Integer;
begin
  if CreateToolTips(Handle) then
  begin
    for i := IDC_BTN_ABOUT to IDC_BTN_COPY do
      AddToolTip(Handle, i, @ti, TOOLTIPS[i - IDC_BTN_ABOUT]);
  end;
end;

procedure SetStatusbar(Handle: THandle; lParam: LPARAM; wParam: WPARAM);
var
  Panels: array[0..1] of Integer;
begin
  SetWindowPos(GetDlgItem(Handle, IDC_SBR), 0, 0, hiword(lParam) - 22, loword(lParam), 0, SWP_SHOWWINDOW);
  Panels[0] := loword(lParam) - 70;
  Panels[1] := -1;
  SendDlgItemMessage(Handle, IDC_SBR, SB_SETPARTS, 2, Integer(@Panels));
  SendDlgItemMessage(Handle, IDC_SBR, SB_SETTEXT, 1, Integer(PChar(GetFileVersion(ParamStr(0)))));
end;

procedure MoveClientWindows(Handle: THandle; lParam: LPARAM; wParam: WPARAM);
begin
  MoveWindow(GetDlgItem(Handle, IDC_STC_BANNER), 0, 0, loword(lParam), 75, TRUE);
  SetWindowPos(GetDlgItem(Handle, IDC_BTN_ABOUT), GetDlgItem(Handle, IDC_STC_BANNER), loword(lParam) - 47, 7, 40, 22, 0);
  MoveWindow(GetDlgItem(Handle, IDC_STC_DEVIDER), 0, 77, loword(lParam), 2, True);
end;

procedure MoveWindowWithMouse(Handle: THandle; lParam: LPARAM);
begin
  SetCursor(LoadCursor(0, IDC_SIZEALL));
  SendMessage(Handle, WM_NCLBUTTONDOWN, HTCAPTION, lParam);
end;