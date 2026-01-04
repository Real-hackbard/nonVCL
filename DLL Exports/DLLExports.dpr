program DLLExports;

uses
  windows, messages, CommCtrl, CommDlg, TDLLClass;

{$R resource.res}
{$INCLUDE GUITools.inc}
{$INCLUDE AppTools.inc}

const

  IDC_BTNABOUT = 101;
  IDC_LV       = 102;
  IDC_BTNOPEN  = 103;
  IDC_STCPATH  = 104;
  IDC_STATBAR  = 105;

  ID_ACCEL_CLOSE = 4001;

  FontName    = 'MS Shell Dlg';
  FontSize    = -18;

const

  APPNAME = 'DLLExports';
  VER     = '1.0';

  INFO_TEXT =  APPNAME+' '+VER+' '+#13+#10+
               'Copyright © Your Name'+#13+#10+
               'https://github.com/';

var
  hApp, hAccelTbl: Cardinal;
  msg: TMsg;
  ofn : TOpenFileName;

  whitebrush: HBRUSH = 0;

  WhiteLB: TLogBrush =
  (
    lbStyle: BS_SOLID;
    lbColor: $00FFFFFF;
    lbHatch: 0
  );

function IntToStr(Int: integer): string;
begin
  Str(Int, result);
end;

procedure MakeColumns;
var
  lvc : TLVColumn;
begin
  lvc.mask := LVCF_TEXT or LVCF_WIDTH ;
  lvc.pszText := 'Orginal';
  lvc.cx := 95;
  SendMessage(GetDlgItem(hApp, IDC_LV), LVM_INSERTCOLUMN, 0, Integer(@lvc));
  lvc.pszText := 'Hint';
  SendMessage(GetDlgItem(hApp, IDC_LV), LVM_INSERTCOLUMN, 1, Integer(@lvc));
  lvc.pszText := 'Functionname';
  lvc.cx := 260;
  SendMessage(GetDlgItem(hApp, IDC_LV), LVM_INSERTCOLUMN, 2, Integer(@lvc));
  lvc.pszText := 'Entry point';
  SendMessage(GetDlgItem(hApp, IDC_LV), LVM_INSERTCOLUMN, 3, Integer(@lvc));
end;

//const
//        OPENFILENAME_SIZE_VERSION_400 : Cardinal = $000004C;
//
//function IsNT5OrHigher: Boolean;
//var
//  ovi: TOSVERSIONINFO;
//begin
//  ZeroMemory(@ovi, sizeof(TOSVERSIONINFO));
//  ovi.dwOSVersionInfoSize := SizeOf(TOSVERSIONINFO);
//  GetVersionEx(ovi);
//  if (ovi.dwPlatformId = VER_PLATFORM_WIN32_NT) AND (ovi.dwMajorVersion >= 5) then
//    result := TRUE
//  else
//    result := FALSE;
//end;

function OpenDLL: String;
var
  Filter, s : String;
  buffer : array[0..MAX_PATH] of Char;
begin
  Filter := 'Known file types (*.dll;*.sys)'#0'*.dll;*.sys'#0 +
    'Program library (*.dll)'#0'*.dll'#0 +
    'Systemfile (*.sys)'#0'*.sys'#0 +
    'All Files (*.*)'#0'*.sys'#0 +
    #0;
  Zeromemory(@buffer, sizeof(buffer));
  ofn.lStructSize := SizeOf(TOpenFilename) - (SizeOf(DWORD) shl 1) - SizeOf(Pointer);
  ofn.hWndOwner := hApp;
  ofn.hInstance := hInstance;
  ofn.lpstrFilter := @Filter[1];
  ofn.lpstrFile := buffer;
  ofn.nMaxFile := 256;
  ofn.Flags := OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_LONGNAMES;

  if GetOpenFileName(ofn) then
  begin
    s := String(ofn.lpstrFile);
  end;
  result := s;
end;

procedure FillLV(Filename: String);
var
  DLLInfo: TDLLInfo;
  ExpIndex: Integer;
  ExpEntry: TDLLInfoExportEntry;
  Text: string;
  lvi : TLVItem;
begin
  DLLInfo := TDLLInfo.create(Filename);
  SendDlgItemMessage(hApp, IDC_LV, LVM_DELETEALLITEMS, 0, 0);
  lvi.mask := LVIF_TEXT;
  try
    SendDlgItemMessage(hApp, IDC_LV, WM_SETREDRAW, Integer(FALSE), 0);
    for ExpIndex := 0 to DLLInfo.ExportCount - 1 do
    begin
      ExpEntry := DLLInfo.ExportEntry[ExpIndex];

      lvi.iItem := ExpIndex;
      Text := IntToStr(ExpEntry.Ordinal);
      lvi.pszText := PChar(Text);
      lvi.iSubItem := 0;
      SendDlgItemMessage(hApp, IDC_LV, LVM_INSERTITEM, 0, Integer(@lvi));

      Text := IntToStr(ExpEntry.Hint);
      lvi.pszText := PChar(Text);
      lvi.iSubItem := 1;
      SendDlgItemMessage(hApp, IDC_LV, LVM_SETITEM, 0, Integer(@lvi));

      Text := ExpEntry.Name;
      lvi.pszText := PChar(Text);
      lvi.iSubItem := 2;
      SendDlgItemMessage(hApp, IDC_LV, LVM_SETITEM, 0, Integer(@lvi));

      if (ExpEntry.VaAddr = 0) then
        Text := PChar(ExpEntry.FwdName)
      else
        Text := Format('%.8X', [ExpEntry.VaAddr]);
      lvi.pszText := PChar(Text);
      lvi.iSubItem := 3;
      SendDlgItemMessage(hApp, IDC_LV, LVM_SETITEM, 0, Integer(@lvi));
    end;
    SendDlgItemMessage(hApp, IDC_LV, WM_SETREDRAW, Integer(TRUE), 0);
    Text := 'Version: '+DLLInfo.Version;
    SendDlgItemMessage(hApp, IDC_STATBAR, SB_SETTEXT, 0, Integer(@Text[1]));
    Text := 'Exported functions: '+IntToStr(DLLInfo.ExportCount);
    SendDlgItemMessage(hApp, IDC_STATBAR, SB_SETTEXT, 1, Integer(@Text[1]));
  finally
    DLLInfo.Free;
  end;
end;

function dlgfunc(hDlg: hWnd; uMsg: dword; wParam: wParam; lParam: lParam): bool;
  stdcall;
var
  MyFont : HFONT;
  s      : String;
  hStatusbar : Cardinal;
  PanelWidth  : array[0..2] of Integer;
  hIcon: Cardinal;
begin
  result := true;
  case uMsg of
    WM_INITDIALOG:
    begin
      hApp := hDlg;
      SendMessage(hDlg, WM_SETICON, ICON_SMALL, Integer(LoadIcon(hInstance,
        MAKEINTRESOURCE(1))));
      hIcon := Loadicon(hInstance, MAKEINTRESOURCE(3));
      SendDlgItemMessage(hDlg, 998, STM_SETICON, hIcon, 0);
      MyFont := CreateFont(FontSize, 0, 0, 0, 900, 0, 0, 0, ANSI_CHARSET,
        OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
        DEFAULT_PITCH, FontName);
      if MyFont <> 0 then
        SendDlgItemMessage(hDlg, 999, WM_SETFONT, Integer(MyFont),Integer(true));
      s := APPNAME+' '+VER;
      SetWindowText(hDlg, pointer(s));
      SetDlgItemText(hDlg, 999, pointer(s));
      MakeColumns;
      SendDlgItemMessage(hDlg, IDC_LV, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, LVS_EX_FULLROWSELECT);
      hStatusBar := CreateStatusWindow(WS_VISIBLE or WS_CHILD, nil, hDlg, IDC_STATBAR);
      PanelWidth[0] := 125;
      PanelWidth[1] := 360;
      PanelWidth[2] := -1;
      SendMessage(hStatusbar, SB_SETPARTS, 2, Integer(@PanelWidth));
      s := 'Version: ';
      SendDlgItemmessage(hDlg, IDC_STATBAR, SB_SETTEXT, 0, Integer(@s[1]));
      s := 'Exported functions: ';
      SendDlgItemmessage(hDlg, IDC_STATBAR, SB_SETTEXT, 1, Integer(@s[1]));
      CreateToolTips(hDlg);
      AddToolTip(hDlg, IDC_BTNABOUT, @ti, 'Information about the program');
      AddToolTip(hDlg, IDC_BTNOPEN, @ti, 'Open File');
    end;
    WM_CTLCOLORSTATIC:
    begin
      case GetDlgCtrlId(lParam) of
        999:
        begin
          whitebrush := CreateBrushIndirect(WhiteLB);
          SetBkColor(wParam, WhiteLB.lbColor);
          result := BOOL(whitebrush);
        end;
      end;
    end;
    WM_LBUTTONDOWN: SendMessage(hDlg, WM_NCLBUTTONDOWN, HTCAPTION, lParam);
    WM_SIZE:
    begin
      MoveWindow(GetDlgItem(hDlg, 999), 0, 0, loword(lParam), 75, TRUE);
      s := APPNAME+' '+VER;
      SetDlgItemText(hDlg, 999, pointer(s));
      SetWindowPos(GetDlgItem(hDlg, 101),
                   GetDlgItem(hDlg, 999),
                   loword(lParam)-47, 7, 40, 22, 0);

      SetWindowPos(GetDlgItem(hDlg, IDC_LV),
                   0,
                   0,
                   110,
                   loword(lParam),
                   hiword(lParam)-130,
                   SWP_NOZORDER);

      MoveWindow(GetDlgItem(hDlg, IDC_STATBAR),
                 0, HIWORD(lParam),
                 LOWORD(lParam),
                 0,
                 TRUE);

      SetWindowPos(GetDlgItem(hDlg, IDC_STCPATH),
                   0, 10, 84,
                   loword(lParam)-105, 18, 0);

      SetWindowPos(GetDlgItem(hDlg, IDC_BTNOPEN),
                   0,
                   loword(lParam)-85, 82, 75, 22, 0);
    end;
    WM_CLOSE:
    begin
      DestroyWindow(hDlg);
      PostQuitMessage(0);
    end;
    WM_COMMAND:
    begin
      if hiword(wParam) = BN_CLICKED then
      begin
        case LoWord(wParam) of
          IDC_BTNABOUT: MyMessagebox(hDlg, INFO_TEXT, 2);
          IDC_BTNOPEN:
          begin
            s := OpenDLL;
            SetDlgItemText(hDlg, IDC_STCPATH, pointer(s));
            if s <> '' then FillLV(s);
          end;
        end;
      end;
      if hiword(wParam) = 1 then  // Accelerator
      begin
        case loword(wParam) of
          ID_ACCEL_CLOSE: SendMessage(hDlg, WM_CLOSE, 0, 0);
        end;
      end;
    end
  else result := false;
  end;
end;

begin
  InitCommonControls;
  CreateDialog(hInstance, MAKEINTRESOURCE(100), 0, @dlgfunc);
  hAccelTbl := LoadAccelerators(hInstance, MAKEINTRESOURCE(4000));
  while true do
  begin
    if not GetMessage(msg, 0, 0, 0) then
      break;
    if TranslateAccelerator(hApp, hAccelTbl, msg) = 0 then
    if IsDialogMessage(hApp, msg) = FALSE then
    begin
      TranslateMessage(msg);
      DispatchMessage(msg);
    end;
  end;
  ExitCode := msg.wParam;
end.

