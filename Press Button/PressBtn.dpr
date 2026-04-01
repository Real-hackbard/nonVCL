program PressBtn;

{$R Res\Resource.res}

uses
  Windows, Messages, ShellAPI;

{$E exe}

const
  IDI_NICO          = MakeIntResource(101);
  IDI_DOWN          = MakeIntResource(102);
  IDI_BASE          = MakeIntResource(103);
  IDC_DRAG          = MakeIntResource(104);
  IDC_LINK          = MakeIntResource(105);
  IDD_MAIN          = MakeIntResource(106);
  IDC_SELECT        = 1002;
  IDC_CLASS         = 1005;
  IDC_HANDLE        = 1006;
  IDC_DAY           = 1009;
  IDC_MONTH         = 1010;
  IDC_YEAR          = 1011;
  IDC_HOUR          = 1012;
  IDC_MINUTE        = 1013;
  IDC_SECOND        = 1014;
  IDC_CLOSETARGET   = 1018;
  IDC_CLOSESELF     = 1019;
  IDC_START         = 1020;
  IDC_STOP          = 1021;
  IDC_EXIT          = 1022;
  IDS_INVALIDHANDLE = 1;
  IDS_TIMEEXPIRED   = 2;
  IDS_INVALIDTIME   = 3;
  IDS_WNDNOWINVALID = 4;

var
  NicoIcon: HICON;
  BaseIcon: HICON;
  DownIcon: HICON;

var
  ResStrInvalidHandle: ShortString;
  ResStrTimeExpired: ShortString;
  ResStrInvalidTime: ShortString;
  ResStrWndNowInalid: ShortString;

const
  PressTimerId = 555;

var
  PressTimer: UINT;
  PressTime: TLargeInteger;  // TFileTime;

const
  WM_SHELLNOTIFY = WM_USER + 5;
  IDI_TRAY = 0;

var
  NotifyIconData: TNotifyIconData;
  AppMinimized: Boolean;

procedure EnableDlgItems(Dlg: HWND; Started: Boolean);
begin
  EnableWindow(GetDlgItem(Dlg, IDC_START), not Started);
  EnableWindow(GetDlgItem(Dlg, IDC_STOP), Started);
  EnableWindow(GetDlgItem(Dlg, IDC_DAY), not Started);
  EnableWindow(GetDlgItem(Dlg, IDC_MONTH), not Started);
  EnableWindow(GetDlgItem(Dlg, IDC_YEAR), not Started);
  EnableWindow(GetDlgItem(Dlg, IDC_HOUR), not Started);
  EnableWindow(GetDlgItem(Dlg, IDC_MINUTE), not Started);
  EnableWindow(GetDlgItem(Dlg, IDC_SECOND), not Started);
end;

function DlgProc(Dlg: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): BOOL; stdcall;
var
  Menu: HMENU;
  SystemTime: TSystemTime;
  FileTime: TLargeInteger;
  Translated: BOOL;
  Point: TPoint;
  Target: HWND;
  TargetId: HWND;
  Text: array [0..1024] of Char;
  Error: Integer;
begin
  Result := False;
  case Msg of
    WM_INITDIALOG:
      begin
        SetFocus(GetDlgItem(Dlg, IDC_HOUR));
        NicoIcon := LoadIcon(HInstance, IDI_NICO);
        BaseIcon := LoadIcon(HInstance, IDI_BASE);
        DownIcon := LoadIcon(HInstance, IDI_DOWN);
        SendMessage(Dlg, WM_SETICON, ICON_SMALL, NicoIcon);
        SendMessage(Dlg, WM_SETICON, ICON_BIG, NicoIcon);
        Menu := GetSystemMenu(Dlg, False);
        EnableMenuItem(Menu, SC_MAXIMIZE, MF_BYCOMMAND or MF_DISABLED or MF_GRAYED);
        EnableMenuItem(Menu, SC_RESTORE, MF_BYCOMMAND or MF_DISABLED or MF_GRAYED);
        EnableMenuItem(Menu, SC_SIZE, MF_BYCOMMAND or MF_DISABLED or MF_GRAYED);
        GetLocalTime(SystemTime);
        SetDlgItemInt(Dlg, IDC_DAY, SystemTime.wDay, False);
        SetDlgItemInt(Dlg, IDC_MONTH, SystemTime.wMonth, False);
        SetDlgItemInt(Dlg, IDC_YEAR, SystemTime.wYear, False);
        SetDlgItemInt(Dlg, IDC_HOUR, SystemTime.wHour, False);
        SetDlgItemInt(Dlg, IDC_MINUTE, SystemTime.wMinute, False);
        SetDlgItemInt(Dlg, IDC_SECOND, 0, False);
        SetLength(ResStrInvalidHandle, LoadString(HInstance, IDS_INVALIDHANDLE,
          PChar(@ResStrInvalidHandle[1]), High(ShortString)));
        SetLength(ResStrTimeExpired, LoadString(HInstance, IDS_TIMEEXPIRED,
          PChar(@ResStrTimeExpired[1]), High(ShortString)));
        SetLength(ResStrInvalidTime, LoadString(HInstance, IDS_INVALIDTIME,
          PChar(@ResStrInvalidTime[1]), High(ShortString)));
        SetLength(ResStrWndNowInalid, LoadString(HInstance, IDS_WNDNOWINVALID,
          PChar(@ResStrWndNowInalid[1]), High(ShortString)));
        CheckDlgButton(Dlg, IDC_CLOSESELF, BST_CHECKED);
      end;
    WM_CLOSE:
      begin
        if AppMinimized then
          Shell_NotifyIcon(NIM_DELETE, @NotifyIconData);
        EndDialog(Dlg, 0);
      end;
    WM_LBUTTONDOWN:
      begin
        Point.x := LOWORD(LParam);
        Point.y := HiWord(LParam);
        if ChildWindowFromPoint(Dlg, Point) = GetDlgItem(Dlg, IDC_SELECT) then
        begin
          SetCapture(Dlg);
          SetCursor(LoadCursor(HInstance, IDC_DRAG));
          SendDlgItemMessage(Dlg, IDC_SELECT, STM_SETIMAGE, IMAGE_ICON,
            Integer(BaseIcon));
        end
        else
          Result := True;
      end;
    WM_MOUSEMOVE:
      if (GetCapture = Dlg) and GetCursorPos(Point) then
      begin
        Target := WindowFromPoint(Point);
        if GetClassName(Target, Text, SizeOf(Text)) = 0 then
          Text[0] := #0;
        SetDlgItemText(Dlg, IDC_CLASS, Text);
        if wvsprintf(Text, '$%8.8X', PChar(@Target)) = 0 then
          Text[0] := #0;
        SetDlgItemText(Dlg, IDC_HANDLE, Text);
      end
      else
        Result := True;
    WM_LBUTTONUP:
      if GetCapture = Dlg then
        ReleaseCapture
      else
        Result := True;
    WM_CAPTURECHANGED:
      begin
        SetCursor(LoadCursor(HInstance, IDC_ARROW));
        SendDlgItemMessage(Dlg, IDC_SELECT, STM_SETIMAGE, IMAGE_ICON,
          Integer(DownIcon));
      end;
    WM_COMMAND:
      if HiWord(WParam) = BN_CLICKED then
      begin
        case LOWORD(WParam) of
          IDC_EXIT:
            SendMessage(Dlg, WM_CLOSE, 0, 0);
          IDC_START:
            begin
              FillChar(SystemTime, SizeOf(TSystemTime), 0);
              SystemTime.wDay := GetDlgItemInt(Dlg, IDC_DAY, Translated, False);
              SystemTime.wMonth := GetDlgItemInt(Dlg, IDC_MONTH, Translated, False);
              SystemTime.wYear := GetDlgItemInt(Dlg, IDC_YEAR, Translated, False);
              SystemTime.wHour := GetDlgItemInt(Dlg, IDC_HOUR, Translated, False);
              SystemTime.wMinute := GetDlgItemInt(Dlg, IDC_MINUTE, Translated, False);
              SystemTime.wSecond := GetDlgItemInt(Dlg, IDC_SECOND, Translated, False);
              if SystemTimeToFileTime(SystemTime, TFileTime(PressTime)) then
              begin
                GetLocalTime(SystemTime);
                SystemTimeToFileTime(SystemTime, TFileTime(FileTime));
                if FileTime <= PressTime then
                begin
                  if GetDlgItemText(Dlg, IDC_HANDLE, Text, SizeOf(Text)) = 0 then
                    Text[0] := #0;
                  Val(string(Text), Target, Error);
                  if (Error = 0) and IsWindow(Target) and
                    ((GetParent(Target) <> 0) or (IsDlgButtonChecked(Dlg, IDC_CLOSETARGET) = BST_CHECKED))	then
                  begin
                    PressTimer := SetTimer(Dlg, PressTimerId, 1000, nil);
                    EnableDlgItems(Dlg, True);
                  end
                  else
                    MessageBox(Dlg, PChar(@ResStrInvalidHandle[1]), nil, MB_ICONEXCLAMATION);
                end
                else
                  MessageBox(Dlg, PChar(@ResStrTimeExpired[1]), nil, MB_ICONEXCLAMATION);
              end
              else
                MessageBox(Dlg, PChar(@ResStrInvalidTime[1]), nil, MB_ICONERROR);
            end;
          IDC_STOP:
            begin
              if PressTimer <> 0 then
              begin
                KillTimer(Dlg, PressTimer);
                PressTimer := 0;
              end;
              EnableDlgItems(Dlg, False);
            end;
        end;
      end
      else
        Result := True;
    WM_TIMER:
      if WParam = PressTimerId then
      begin
        if GetDlgItemText(Dlg, IDC_HANDLE, Text, SizeOf(Text)) = 0 then
          Text[0] := #0;
        Val(string(Text), Target, Error);
        if (Error = 0) and IsWindow(Target) then
        begin
          GetLocalTime(SystemTime);
          SystemTimeToFileTime(SystemTime, TFileTime(FileTime));
          if FileTime >= PressTime then
          begin
            KillTimer(Dlg, PressTimer);
            PressTimer := 0;

            if IsDlgButtonChecked(Dlg, IDC_CLOSETARGET) = BST_CHECKED	then
            begin
              // Send a close message to the window
              while (GetParent(Target) <> 0) and (GetParent(Target) <> GetDesktopWindow) do
                Target := GetParent(Target);
              SendMessage(Target, WM_CLOSE, 0, 0);
            end
            else
            begin
              // Send button press message to parent
              TargetId := GetDlgCtrlID(Target);
              SendMessage(GetParent(Target), WM_COMMAND, BN_CLICKED shl 16 or Word(TargetId), Target);
            end;

            if IsDlgButtonChecked(Dlg, IDC_CLOSESELF) = BST_CHECKED	then
              SendMessage(Dlg, WM_CLOSE, 0, 0)
            else
              EnableDlgItems(Dlg, False);
          end;
        end
        else
        begin
          KillTimer(Dlg, PressTimer);
          PressTimer := 0;
          MessageBox(Dlg, PChar(@ResStrWndNowInalid[1]), nil, MB_ICONEXCLAMATION);
          EnableDlgItems(Dlg, False);
        end;
      end
      else
        Result := True;
    WM_SIZE:
      if WParam = SIZE_MINIMIZED then
      begin
        AppMinimized := True;
        NotifyIconData.cbSize := SizeOf(TNotifyIconData);
        NotifyIconData.Wnd := Dlg;
        NotifyIconData.uID := IDI_TRAY;
        NotifyIconData.uFlags := NIF_ICON or NIF_MESSAGE or NIF_TIP;
        NotifyIconData.uCallbackMessage := WM_SHELLNOTIFY;
        NotifyIconData.hIcon := NicoIcon;
        GetWindowText(Dlg, Text, SizeOf(Text));
        lstrcpy(NotifyIconData.szTip, Text);
        ShowWindow(Dlg, SW_HIDE);
        Shell_NotifyIcon(NIM_ADD, @NotifyIconData);
      end
      else
        Result := True;
    WM_SHELLNOTIFY:
      if (WParam = IDI_TRAY) and
        ((LParam = WM_LBUTTONUP) or (LParam = WM_RBUTTONUP)) then
      begin
        AppMinimized := False;
        Shell_NotifyIcon(NIM_DELETE, @NotifyIconData);
        ShowWindow(Dlg, SW_RESTORE);
      end
      else
        Result := True;
  end;
end;

begin
  DialogBoxParam(HInstance, IDD_MAIN, 0, @DlgProc, 0);
end.

