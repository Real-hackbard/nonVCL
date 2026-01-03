program EnumWindows;

{$R resource.res}

uses
  windows, messages, CommCtrl, tlhelp32;

{$INCLUDE AppTools.inc}
{$INCLUDE GUITools.inc}

const
  IDC_LV = 101;
  IDC_BTNABOUT = 103;

  IDA_REFRESH = 4001;

  FontName    = 'Tahoma';
  FontSize    = -18;

const
  APPNAME = 'Enum Windows';
  VER     = '1.0';
  INFO_TEXT =  APPNAME+' '+VER+' '+#13+#10+
               'Copyright © Your Name'+#13+#10+
               'https://github.com';

var
  hLV        : Cardinal;
  WindowSort : Byte = 1;
  HandleSort : Byte = 1;
  ClassSort  : Byte = 1;
  PathSort   : Byte = 1;
  ProcSort   : Byte = 1;
  AppSort    : Byte = 1;

  whitebrush: HBRUSH = 0;

  WhiteLB: TLogBrush =
  (
    lbStyle: BS_SOLID;
    lbColor: $00FFFFFF;
    lbHatch: 0
  );

function ExtractFileName(const FileName: String): String; 
var
   RPos: Integer;
begin
   RPos := Length(FileName);
   while not (FileName[RPos] in ['\', ':']) and (RPos > 0) do
      Dec(RPos);
   Result := Copy(FileName, RPos + 1, MaxInt);
end;

procedure MakeColumns;
var
  lvc: TLVColumn;
begin
  {Text & cx member (column width) is valid}
  lvc.mask := LVCF_TEXT or LVCF_WIDTH;
  lvc.pszText := 'Window title';
  lvc.cx := 200;
  SendMessage(hLV, LVM_INSERTCOLUMN, 0, Integer(@lvc));
  lvc.mask := lvc.mask;
  lvc.pszText := 'Window handle';
  lvc.cx := 85;
  SendMessage(hLV, LVM_INSERTCOLUMN, 1, Integer(@lvc));
  lvc.pszText := 'Window class';
  lvc.cx := 145;
  SendMessage(hLV, LVM_INSERTCOLUMN, 2, Integer(@lvc));
  lvc.pszText := 'ProzessID';
  lvc.cx := 85;
  SendMessage(hLV, LVM_INSERTCOLUMN, 3, Integer(@lvc));
  lvc.pszText := 'Application';
  lvc.cx := 85;
  SendMessage(hLV, LVM_INSERTCOLUMN, 4, Integer(@lvc));
end;

function GetAppFromProcID(ID: Cardinal): String;
var
  hSnap: Cardinal;
  me32: TMODULEENTRY32;
begin
  hSnap := CreateToolHelp32SnapShot(TH32CS_SNAPMODULE, ID);
  if hSnap = INVALID_HANDLE_VALUE then exit;
  me32.dwSize := sizeof(TMODULEENTRY32);;
  Module32First(hSnap, me32);
  result := ExtractFileName(me32.szExePath);
end;

function CompareItems(lParam1, lParam2, SortType: lParam): Integer; stdcall;
var
  buffer: array[0..255] of Char;
  buffer1: array[0..255] of Char;
  lvi: TLVItem;
begin
  result := -1;
  lvi.mask := LVIF_TEXT;
  lvi.pszText := buffer;
  lvi.cchTextMax := 256;
  case SortType of
    0:
      begin
        lvi.iSubItem := 0;
        SendMessage(hLV, LVM_GETITEMTEXT, lParam1, Integer(@lvi));
        lstrcpy(buffer1, buffer);
        SendMessage(hLV, LVM_GETITEMTEXT, lParam2, Integer(@lvi));
        result := lstrcmp(buffer1, buffer);
      end;
    1:
      begin
        lvi.iSubItem := 0;
        SendMessage(hLV, LVM_GETITEMTEXT, lParam1, Integer(@lvi));
        lstrcpy(buffer1, buffer);
        SendMessage(hLV, LVM_GETITEMTEXT, lParam2, Integer(@lvi));
        result := lstrcmp(buffer, buffer1);
      end;
    2:
      begin
        lvi.iSubItem := 1;
        SendMessage(hLV, LVM_GETITEMTEXT, lParam1, Integer(@lvi));
        lstrcpy(buffer1, buffer);
        SendMessage(hLV, LVM_GETITEMTEXT, lParam2, Integer(@lvi));
        result := lstrcmp(buffer1, buffer);
      end;
    3:
      begin
        lvi.iSubItem := 1;
        SendMessage(hLV, LVM_GETITEMTEXT, lParam1, Integer(@lvi));
        lstrcpy(buffer1, buffer);
        SendMessage(hLV, LVM_GETITEMTEXT, lParam2, Integer(@lvi));
        result := lstrcmp(buffer, buffer1);
      end;
    4:
      begin
        lvi.iSubItem := 2;
        SendMessage(hLV, LVM_GETITEMTEXT, lParam1, Integer(@lvi));
        lstrcpy(buffer1, buffer);
        SendMessage(hLV, LVM_GETITEMTEXT, lParam2, Integer(@lvi));
        result := lstrcmp(buffer, buffer1);
      end;
    5:
      begin
        lvi.iSubItem := 2;
        SendMessage(hLV, LVM_GETITEMTEXT, lParam1, Integer(@lvi));
        lstrcpy(buffer1, buffer);
        SendMessage(hLV, LVM_GETITEMTEXT, lParam2, Integer(@lvi));
        result := lstrcmp(buffer1, buffer);
      end;
    6:
      begin
        lvi.iSubItem := 3;
        SendMessage(hLV, LVM_GETITEMTEXT, lParam1, Integer(@lvi));
        lstrcpy(buffer1, buffer);
        SendMessage(hLV, LVM_GETITEMTEXT, lParam2, Integer(@lvi));
        result := lstrcmp(buffer, buffer1);
      end;
    7:
      begin
        lvi.iSubItem := 3;
        SendMessage(hLV, LVM_GETITEMTEXT, lParam1, Integer(@lvi));
        lstrcpy(buffer1, buffer);
        SendMessage(hLV, LVM_GETITEMTEXT, lParam2, Integer(@lvi));
        result := lstrcmp(buffer1, buffer);
      end;
    8:
      begin
        lvi.iSubItem := 4;
        SendMessage(hLV, LVM_GETITEMTEXT, lParam1, Integer(@lvi));
        lstrcpy(buffer1, buffer);
        SendMessage(hLV, LVM_GETITEMTEXT, lParam2, Integer(@lvi));
        result := lstrcmp(buffer, buffer1);
      end;
    9:
      begin
        lvi.iSubItem := 4;
        SendMessage(hLV, LVM_GETITEMTEXT, lParam1, Integer(@lvi));
        lstrcpy(buffer1, buffer);
        SendMessage(hLV, LVM_GETITEMTEXT, lParam2, Integer(@lvi));
        result := lstrcmp(buffer1, buffer);
      end;
  end;
end;

procedure SortLV;
var
  lvi: TLVItem;
  i: Integer;
begin
  lvi.mask := LVIF_PARAM;
  lvi.iSubItem := 0;
  lvi.iItem := 0;
  for i := 0 to SendMessage(hLV, LVM_GETITEMCOUNT, 0, 0) - 1 do
  begin
    lvi.lParam := lvi.iItem;
    SendMessage(hLV, LVM_SETITEM, 0, Integer(@lvi));
    Inc(lvi.iItem);
  end;
end;

function EnumWindowsProc(const hWnd : Longword; Param: lParam): LongBool; stdcall;
var
  lvi: TLVItem;
  Buffer: array[0..1024] of Char;
  i: DWORD;
  ProcID: Cardinal;
begin
  Result := True;
  i := 0;
  lvi.mask := LVIF_TEXT;
  lvi.pszText := Buffer;

  GetWindowText(hWnd, Buffer, sizeof(Buffer));
  if lstrlen(Buffer) = 0 then exit;
  lvi.iItem := i;
  lvi.iSubItem := 0;
  SendMessage(hLV, LVM_INSERTITEM, 0, Integer(@lvi));

  wvsPrintf(Buffer, '$%X', PChar(@hWnd));
  lvi.iSubItem := 1;
  SendMessage(hLV, LVM_SETITEM, 0, Integer(@lvi));

  GetClassName(hWnd, Buffer, sizeof(Buffer));
  lvi.iSubItem := 2;
  SendMessage(hLV, LVM_SETITEM, 0, Integer(@lvi));

  GetWindowThreadProcessID(hWnd, @ProcID);
  wvsPrintf(Buffer, '%d', PChar(@ProcID));
  lvi.iSubItem := 3;
  SendMessage(hLV, LVM_SETITEM, 0, Integer(@lvi));

  lstrcpy(Buffer, PChar(GetAppFromProcID(ProcID)));
  lvi.iSubItem := 4;
  SendMessage(hLV, LVM_SETITEM, 0, Integer(@lvi));
end;

function dlgfunc(hDlg: hWnd; uMsg: dword; wParam: wParam; lParam: lParam): bool;
  stdcall;
var
  s : String;
  MyFont : HFONT;
begin
  result := true;
  case uMsg of
    WM_INITDIALOG:
    begin
      hLV := GetDlgItem(hDlg, IDC_LV);
      MakeColumns;
      SendMessage(hDlg, WM_SETICON, ICON_BIG, Integer(LoadIcon(hInstance,
        MAKEINTRESOURCE(1))));
      SendMessage(hDlg, WM_SETICON, ICON_SMALL, Integer(LoadIcon(hInstance,
        MAKEINTRESOURCE(1))));

      MyFont := CreateFont(FontSize, 0, 0, 0, 900, 0, 0, 0, ANSI_CHARSET,
        OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
        DEFAULT_PITCH, FontName);
      if MyFont <> 0 then
        SendDlgItemMessage(hDlg, 999, WM_SETFONT, Integer(MyFont),Integer(true));
      s := APPNAME+' '+VER;
      SetWindowText(hDlg, pointer(s));
      SetDlgItemText(hDlg, 999, pointer(s));

      SendDlgItemMessage(hDlg, IDC_LV, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, LVS_EX_FULLROWSELECT);

      CreateToolTips(hDlg);
      AddToolTip(hDlg, IDC_BTNABOUT, @ti, 'Information about the program');
      AddToolTip(hDlg, IDC_LV, @ti, 'Aktualisieren mit F5');

      Windows.EnumWindows(@EnumWindowsProc, Integer(@lParam));
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
    WM_COMMAND:
    begin
      if hiword(wParam) = BN_CLICKED then
      begin
        case LoWord(wParam) of
          IDC_BTNABOUT: MyMessagebox(hDlg, 'Information...', INFO_TEXT, 2);
        end;
      end;
      if hiword(wParam) = 1 then  // Accelerator
      begin
        case loword(wParam) of
          IDA_REFRESH:
          begin
            SendDlgItemMessage(hDlg, IDC_LV, LVM_DELETEALLITEMS, 0, 0);
            Windows.EnumWindows(@EnumWindowsProc, Integer(@lParam));
          end;
        end;
      end;
    end;
    WM_SIZE:
    begin
      MoveWindow(GetDlgItem(hDlg, 999), 0, 0, loword(lParam), 75, TRUE);
      s := APPNAME+' '+VER;
      SetDlgItemText(hDlg, 999, pointer(s));
      MoveWindow(hLV, 0, 75, loword(lParam), hiword(lParam)-75, TRUE);
      MoveWindow(GetDlgItem(hDlg, IDC_BTNABOUT), loword(lParam)-47, 7, 40, 22, TRUE);
    end;
    WM_NOTIFY:
    begin
      if (wParam = IDC_LV) and (PNMHdr(lParam).code = LVN_COLUMNCLICK) then
          begin
            if PNMListView(lParam)^.iSubItem = 0 then
              case WindowSort of
                0:
                  begin
                    SendMessage(hLV, LVM_SORTITEMS, 0, Integer(@CompareItems));
                    SortLV;
                    WindowSort := 1;
                  end;
                else
                  begin
                    SendMessage(hLV, LVM_SORTITEMS, 1, Integer(@CompareItems));
                    SortLV;
                    WindowSort := 0;
                  end;
              end;
            {See comments above; 2nd column -> iSubItems = 1}
            if PNMListView(lParam)^.iSubItem = 1 then
              case HandleSort of
                0:
                  begin
                    SendMessage(hLV, LVM_SORTITEMS, 2, Integer(@CompareItems));
                    SortLV;
                    HandleSort := 1;
                  end;
                else
                  begin
                    SendMessage(hLV, LVM_SORTITEMS, 3, Integer(@CompareItems));
                    SortLV;
                    HandleSort := 0;
                  end;
              end;
            if PNMListView(lParam)^.iSubItem = 2 then
              case ClassSort of
                0:
                  begin
                    SendMessage(hLV, LVM_SORTITEMS, 4, Integer(@CompareItems));
                    SortLV;
                    ClassSort := 1;
                  end;
                else
                  begin
                    SendMessage(hLV, LVM_SORTITEMS, 5, Integer(@CompareItems));
                    SortLV;
                    ClassSort := 0;
                  end;
              end;
            if PNMListView(lParam)^.iSubItem = 3 then
              case ProcSort of
                0:
                  begin
                    SendMessage(hLV, LVM_SORTITEMS, 6, Integer(@CompareItems));
                    SortLV;
                    ProcSort := 1;
                  end;
                else
                  begin
                    SendMessage(hLV, LVM_SORTITEMS, 7, Integer(@CompareItems));
                    SortLV;
                    ProcSort := 0;
                  end;
              end;
            if PNMListView(lParam)^.iSubItem = 4 then
              case AppSort of
                0:
                  begin
                    SendMessage(hLV, LVM_SORTITEMS, 8, Integer(@CompareItems));
                    SortLV;
                    AppSort := 1;
                  end;
                else
                  begin
                    SendMessage(hLV, LVM_SORTITEMS, 9, Integer(@CompareItems));
                    SortLV;
                    AppSort := 0;
                  end;
              end;
          end;
    end;
    WM_CLOSE:
    begin
      DestroyWindow(hDlg);
      PostQuitMessage(0);
    end;
  else result := false;
  end;
end;

var
  hDialog: THandle;
  hAccelTbl: THandle;
  msg: TMsg;

begin
  InitCommonControls;

  hDialog := CreateDialog(hInstance, MAKEINTRESOURCE(100), 0, @dlgfunc);

  hAccelTbl := LoadAccelerators(hInstance, MAKEINTRESOURCE(4000));

  while true do
  begin
    if not GetMessage(msg, 0, 0, 0) then
      break;
    if TranslateAccelerator(hDialog, hAccelTbl, msg) = 0 then
    if IsDialogMessage(hDialog, msg) = FALSE then
    begin
      TranslateMessage(msg);
      DispatchMessage(msg);
    end;
  end;
  ExitCode := msg.wParam;
end.

